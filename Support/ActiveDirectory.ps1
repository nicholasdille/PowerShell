function Get-DomainControllers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
    )

    #region retrieve domain controllers
    $DomainControllers = Resolve-DnsName -Name $DomainName -Type NS | Where-Object {$_.Type -ieq 'A'} | Select-Object -ExpandProperty Name
    Write-Verbose ('Obtained the following domain controllers: {0}' -f ($DomainControllers -join ', '))
    foreach ($DomainController in $DomainControllers) {
        Write-Verbose ('Processing domain controller <{0}>' -f $DomainController)

        # extract hostname for domain controller
        if ($DomainController -imatch '^([^\.]+)\.') {
            $DomainControllerHostname = $Matches[1]
        }
        Write-Verbose ('Hostname for domain controller <{0}> is <{1}>' -f $DomainController, $DomainControllerHostname)

        # get computer object for domain controller
        $result = $null
        try {
            $result = Get-ADComputer -Identity $DomainControllerHostname -Server $DomainController -Credential $Credential
            break

        } catch [System.Security.Authentication.AuthenticationException] {
            throw ('Invalid credentials for domain {0}' -f $DomainName)

        } catch [Microsoft.ActiveDirectory.Management.ADServerDownException] {
            Write-Warning ('Domain controller <{0}> is not available for AD operations' -f $DomainController)

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Warning ('Domain controller <{0}> was not found' -f $DomainControllerHostname)
        }
    }
    # make sure a result was obtained
    if (-Not $result) {
        throw ('Unable to find a domain controller for domain P1U')
    }
    Write-Verbose ('Using domain controller <{0}> for AD operations' -f $DomainController)
    #endregion
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

function New-Group {
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
        $WhatIf
    )

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
        WhatIf         = $WhatIf
    }
    try {
        New-ADGroup @CreateParams
        Write-Verbose ('[{0}] Group <{1}> was successfully created' -f $MyInvocation.MyCommand, $Identity)

    } catch {
        Write-Error ('[{0}] Failed to create group <{1}>' -f $MyInvocation.MyCommand, $GroupName)
    }
    Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
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