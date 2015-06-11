function Get-DomainController {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    PROCESS {
        #region Get-DomainController
        $DomainControllers = Resolve-DnsName -Name $DomainName -Type NS | Where-Object {$_.Type -ieq 'A'} | Select-Object -ExpandProperty Name
        Write-Verbose ('[{0}] Obtained the following domain controllers: {1}' -f $MyInvocation.MyCommand, ($DomainControllers -join ', '))
        foreach ($DomainController in $DomainControllers) {
            Write-Verbose ('[{0}] Processing domain controller <{1}>' -f $MyInvocation.MyCommand, $DomainController)

            # extract hostname for domain controller
            if ($DomainController -imatch '^([^\.]+)\.') {
                $DomainControllerHostname = $Matches[1]
            }
            Write-Verbose ('[{0}] Hostname for domain controller <{1}> is <{2}>' -f $MyInvocation.MyCommand, $DomainController, $DomainControllerHostname)

            # get computer object for domain controller
            $result = $null
            try {
                $params = @{
                    Identity = $DomainControllerHostname
                    Server   = $DomainController
                }
                if ($Credential) { $params.Add('Credential', $Credential) }
                $result = Get-ADComputer @params
                return $result.DNSHostName

            } catch [System.Security.Authentication.AuthenticationException] {
                throw ('Invalid credentials for domain {0}' -f $DomainName)

            } catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
                Write-Warning ('[{0}] Domain controller <{1}> is not available for AD operations' -f $MyInvocation.MyCommand, $DomainController)

            } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                Write-Warning ('[{0}] Domain controller <{0}> was not found' -f $MyInvocation.MyCommand, $DomainControllerHostname)

            } catch {
                Write-Verbose ('[{0}] An unknown exception was thrown. Aborting.' -f $MyInvocation.MyCommand)
                return
            }
        }
        # make sure a result was obtained
        if (-Not $result) {
            throw ('[{0}] Unable to find a domain controller for domain {1}' -f $MyInvocation.MyCommand, $DomainName)
        }
        $result.DNSHostName
        #endregion
    }
}

function Test-Group {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    PROCESS {
        Write-Verbose ('[{0}] Checking existence of group <{1}>' -f $MyInvocation.MyCommand, $Identity)
        $GroupExists = $false
        try {
            $null = Get-ADGroup @PSBoundParameters
            Write-Verbose ('[{0}] Group <{1}> already exists. Skipping.' -f $MyInvocation.MyCommand, $Identity)
            $GroupExists = $true

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            $GroupExists = $false
        }

        Write-Verbose ('[{0}] Returning <{1}>' -f $MyInvocation.MyCommand, $GroupExists)
        return $GroupExists
    }
}

function New-Group {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Category
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Scope
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [switch]
        $Wait
    )

    PROCESS {
        Write-Verbose ('[{0}] Creating group <{1}>' -f $MyInvocation.MyCommand, $Identity)

        $TestParams = @{
            Identity = $Identity
        }
        if ($Server -And $Credential) {
            $TestParams.Add('Server', $Server)
            $TestParams.Add('Credential', $Credential)
        }

        if (Test-Group @TestParams) {
            Write-Verbose ('[{0}] Group already exists. Done.' -f $MyInvocation.MyCommand)
            return
        }

        $CreateParams = @{
            Name           = $Identity
            SamAccountName = $Identity
            GroupCategory  = $Category
            GroupScope     = $Scope
            DisplayName    = $Identity
            Path           = $Path
            Description    = $Description
            Server         = $Server
            Credential     = $Credential
        }
        try {
            New-ADGroup @CreateParams
            Write-Verbose ('[{0}] Group <{1}> was successfully created' -f $MyInvocation.MyCommand, $Identity)

        } catch {
            Write-Error ('[{0}] Failed to create group <{1}>' -f $MyInvocation.MyCommand, $Identity)
            return
        }

        if ($Wait) {
            Wait-ADGroup @TestParams -Verbose
        }

        Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
    }
}

function New-Member {
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MemberOf
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [switch]
        $WhatIf
    )

    Write-Verbose ('[{0}] Adding member <{1}> to group <{2}>' -f $MyInvocation.MyCommand, $Identity, $MemberOf)
    try {
        Add-ADPrincipalGroupMembership @PSBoundParameters

    } catch {
        Write-Error ('[{0}] Failed to set membership of <{1}> in group <{2}>' -f $MyInvocation.MyCommand, $params.Identity, $params.MemberOf)
    }
    Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
}

function Rename-ADGroup {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewName
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [switch]
        $Wait
    )
    
    PROCESS {
        $Renamed = $false

        $param = @{}
        if ($Server) {
            $param.Add('Server', $Server)
        }
        if ($Credential) {
            $param.Add('Credential', $Credential)
        }

        try {
            $Group = Get-ADGroup -Identity $Identity @param
            Write-Verbose ('[{0}] Retrieved object for group name <{1}>' -f $MyInvocation.MyCommand, $Identity)

            Write-Verbose ('[{0}] Setting SamAccountName for group' -f $MyInvocation.MyCommand)
            Set-ADGroup -Identity $Group -SamAccountName $NewName @param -ErrorAction SilentlyContinue

            if ($Description) {
                Write-Verbose ('[{0}] Setting description for group' -f $MyInvocation.MyCommand)
                Set-ADGroup -Identity $Group -Description $Description @param -ErrorAction SilentlyContinue
            }

            Write-Verbose ('[{0}] Setting common name and display name' -f $MyInvocation.MyCommand)
            Rename-ADObject -Identity $Group -NewName $NewName @param -ErrorAction SilentlyContinue

            $Renamed = $true

            if ($Wait) {
                Wait-ADGroup -Identity $NewName @param
            }

        } catch {
            Write-Error ('[{0}] Failed to rename group {1} to {2}' -f $MyInvocation.MyCommand, $Group, $NewName)
            $Renamed = $false
        }

        Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
        $Renamed
    }
}

function Wait-ADGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Delay = 5
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $RetryCount = 0
    )

    PROCESS {
        $param = @{
            Identity = $Identity
        }
        if ($Server) {
            $param.Add('Server', $Server)
        }
        if ($Credential) {
            $param.Add('Credential', $Credential)
        }

        $RetryIndex = 0
        while (
                ($RetryCount -eq 0 -or $RetryIndex -lt $RetryCount) -and
                -not (Test-Group @param -Verbose)
            ) {
            Write-Verbose ('[{0}] Waiting for group' -f $MyInvocation.MyCommand)
            Start-Sleep -Seconds $Delay
            ++$RetryIndex
        }
    }
}