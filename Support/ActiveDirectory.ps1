#Requires -Modules ActiveDirectory

function Get-DomainController {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    PROCESS {
        #region Get-DomainController
        $DomainControllers = Resolve-DnsName -Name $DomainName -Type NS | Where-Object {$_.Type -ieq 'A'} | Select-Object -ExpandProperty Name
        Write-Verbose -Message ('[{0}] Obtained the following domain controllers: {1}' -f $MyInvocation.MyCommand, ($DomainControllers -join ', '))
        $result = $null
        foreach ($DomainController in $DomainControllers) {
            Write-Verbose -Message ('[{0}] Processing domain controller <{1}>' -f $MyInvocation.MyCommand, $DomainController)

            # extract hostname for domain controller
            if ($DomainController -imatch '^([^\.]+)\.') {
                $DomainControllerHostname = $Matches[1]
            }
            Write-Verbose -Message ('[{0}] Hostname for domain controller <{1}> is <{2}>' -f $MyInvocation.MyCommand, $DomainController, $DomainControllerHostname)

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
                Write-Warning -Message ('[{0}] Domain controller <{1}> is not available for AD operations' -f $MyInvocation.MyCommand, $DomainController)

            } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
                Write-Warning -Message ('[{0}] Domain controller <{0}> was not found' -f $MyInvocation.MyCommand, $DomainControllerHostname)

            } catch {
                Write-Verbose -Message ('[{0}] An unknown exception was thrown. Aborting.' -f $MyInvocation.MyCommand)
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    PROCESS {
        Write-Verbose -Message ('[{0}] Checking existence of group <{1}>' -f $MyInvocation.MyCommand, $Identity)
        $GroupExists = $false
        try {
            $null = Get-ADGroup @PSBoundParameters
            Write-Verbose -Message ('[{0}] Group <{1}> already exists. Skipping.' -f $MyInvocation.MyCommand, $Identity)
            $GroupExists = $true

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            $GroupExists = $false
        }

        Write-Verbose -Message ('[{0}] Returning <{1}>' -f $MyInvocation.MyCommand, $GroupExists)
        return $GroupExists
    }
}

function New-Group {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='Low')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Category
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Scope
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [switch]
        $Wait
        ,
        [switch]
        $Force
    )

    PROCESS {
        Write-Verbose -Message ('[{0}] Creating group <{1}>' -f $MyInvocation.MyCommand, $Identity)

        $TestParams = @{
            Identity = $Identity
        }
        if ($Server -And $Credential) {
            $TestParams.Add('Server', $Server)
            $TestParams.Add('Credential', $Credential)
        }

        if (Test-Group @TestParams) {
            Write-Verbose -Message ('[{0}] Group already exists. Done.' -f $MyInvocation.MyCommand)
            return $true
        }

        Write-Verbose -Message ('[{0}] Creating NEW group' -f $MyInvocation.MyCommand)
        $GroupCreated = $false
        if ($Force -or $PSCmdlet.ShouldProcess($Identity, 'Create Active Directory group')) {
            $CreateParams = @{
                Name           = $Identity
                SamAccountName = $Identity
                GroupCategory  = $Category
                GroupScope     = $Scope
                DisplayName    = $Identity
                Path           = $Path
            }
            if ($Description) {
                $CreateParams.Add('Description', $Description)
            }
            if ($Server -And $Credential) {
                $CreateParams.Add('Server',     $Server)
                $CreateParams.Add('Credential', $Credential)
            }
            try {
                Write-Debug -Message ('[{0}] Inside try/catch' -f $MyInvocation.MyCommand)
                New-ADGroup @CreateParams -Confirm:$false -Force:$Force
                #New-ADGroup -Name $Identity -DisplayName $Identity -Description $Description -SamAccountName $Identity -GroupCategory $Category -GroupScope $Scope -Path $Path -Confirm:$false -Force:$Force
                Write-Verbose -Message ('[{0}] Group <{1}> was successfully created' -f $MyInvocation.MyCommand, $Identity)
                $GroupCreated = $true

            } catch {
                Write-Error -Message ('[{0}] Failed to create group <{1}>' -f $MyInvocation.MyCommand, $Identity)
                $GroupCreated = $false
                return $GroupCreated
            }

            if ($Wait) {
                Wait-ADGroup @TestParams -Verbose
            }
        }

        Write-Verbose -Message ('[{0}] Done' -f $MyInvocation.MyCommand)
        return $GroupCreated
    }
}

function New-Member {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $MemberOf
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [switch]
        $WhatIf
    )


    Write-Verbose -Message ('[{0}] Testing for existence of group <{1}>' -f $MyInvocation.MyCommand, $MemberOf)
    $TestParams = @{
        Identity = $MemberOf
    }
    if ($Server)     { $TestParams.Add('Server',     $Server) }
    if ($Credential) { $TestParams.Add('Credential', $Credential) }
    if (-Not (Test-Group @TestParams)) {
        Write-Error -Message ('[{0}] Group <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $MemberOf)
        return $false
    }

    Write-Verbose -Message ('[{0}] Adding member <{1}> to group <{2}>' -f $MyInvocation.MyCommand, $Identity, $MemberOf)
    $MembershipAdded = $false
    try {
        Add-ADPrincipalGroupMembership @PSBoundParameters
        $MembershipAdded = $true

    } catch {
        Write-Error -Message ('[{0}] Failed to set membership of <{1}> in group <{2}>' -f $MyInvocation.MyCommand, $Identity, $MemberOf)
        $MembershipAdded = $false
    }

    Write-Verbose -Message ('[{0}] Done' -f $MyInvocation.MyCommand)
    return $MembershipAdded
}

function Rename-ADGroup {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NewName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Description
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter()]
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

        Write-Verbose -Message ('[{0}] Testing for existence of group <{1}>' -f $MyInvocation.MyCommand, $Identity)
        if (-not (Test-Group -Identity $Identity @param)) {
            Write-Error -Message ('[{0}] Group <{1}> not found. Aborting.' -f $MyInvocation.MyCommand, $Identity)
            return $false
        }

        Write-Verbose -Message ('[{0}] Testing for missing group <{1}>' -f $MyInvocation.MyCommand, $NewName)
        if (Test-Group -Identity $NewName @param) {
            Write-Error -Message ('[{0}] Group <{1}> found. Aborting.' -f $MyInvocation.MyCommand, $NewName)
            return $false
        }

        #$Group = $null
        try {
            #$Group = Get-ADGroup -Identity $Identity @param
            #Write-Verbose -Message ('[{0}] Retrieved object for group name <{1}>' -f $MyInvocation.MyCommand, $Identity)

            Write-Verbose -Message ('[{0}] Setting SamAccountName for group' -f $MyInvocation.MyCommand)
            #Set-ADGroup -Identity $Group -SamAccountName $NewName @param -ErrorAction Stop
            Set-ADGroup -Identity $Identity -SamAccountName $NewName @param -ErrorAction Stop

            if ($Description) {
                Write-Verbose -Message ('[{0}] Setting description for group' -f $MyInvocation.MyCommand)
                #Set-ADGroup -Identity $Group -Description $Description @param -ErrorAction Stop
                Set-ADGroup -Identity $Identity -Description $Description @param -ErrorAction Stop
            }

            Write-Verbose -Message ('[{0}] Setting common name and display name' -f $MyInvocation.MyCommand)
            #Rename-ADObject -Identity $Group -NewName $NewName @param -ErrorAction Stop
            Rename-ADObject -Identity $Identity -NewName $NewName @param -ErrorAction Stop

            $Renamed = $true

            if ($Wait) {
                Wait-ADGroup -Identity $NewName @param
            }

        } catch {
            Write-Error -Message ('[{0}] Failed to rename group {1} to {2}' -f $MyInvocation.MyCommand, $Identity, $NewName)
            $Renamed = $false
        }

        Write-Verbose -Message ('[{0}] Done' -f $MyInvocation.MyCommand)
        $Renamed
    }
}

function Wait-ADGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Identity
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $Server
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $Delay = 5
        ,
        [Parameter()]
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
            Write-Verbose -Message ('[{0}] Waiting for group' -f $MyInvocation.MyCommand)
            Start-Sleep -Seconds $Delay
            ++$RetryIndex
        }
    }
}

function Add-Permission {
    <# TODO
    Permissions: ListDirectory, ReadData, WriteData 
      CreateFiles, CreateDirectories, AppendData 
      ReadExtendedAttributes, WriteExtendedAttributes, Traverse
      ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes 
      WriteAttributes, Write, Delete 
      ReadPermissions, Read, ReadAndExecute 
      Modify, ChangePermissions, TakeOwnership
      Synchronize, FullControl
    [System.Security.AccessControl.PropagationFlags]
    Deny
    Registry
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Group
        ,
        [Parameter(Mandatory,ParameterSetName='Simple')]
        [ValidateSet('Full', 'Read', 'Modify', 'List')]
        [string]
        $PermissionSetName
        ,
        [Parameter(Mandatory,ParameterSetName='Custom')]
        [System.Security.AccessControl.FileSystemRights[]]
        $Permission
        ,
        [Parameter(ParameterSetName='Simple')]
        [switch]
        $EnableInheritance
        ,
        [Parameter(ParameterSetName='Custom')]
        [System.Security.AccessControl.InheritanceFlags[]]
        $Inheritance = 'None'
    )

    PROCESS {
        Write-Verbose -Message ('[{0}] Checking specified path <{1}>' -f $MyInvocation.MyCommand, $Path)
        if (-Not (Test-Path -Path $Path)) {
            throw ('[{0}] The specified path <{1}> does not exist' -f $MyInvocation.MyCommand, $Path)
        }

        Write-Verbose -Message ('[{0}] Processing parameters' -f $MyInvocation.MyCommand)
        if ($PSCmdlet.ParameterSetName -ieq 'Simple') {
            Write-Verbose -Message ('[{0}] Translating simple parameters to internal names' -f $MyInvocation.MyCommand)

	        switch ($PermissionSetName) {
		        full   { $Permission = 'FullControl' }
		        read   { $Permission = 'ReadAndExecute' }
		        modify { $Permission = 'Modify' }
		        list   { $Permission = ('ReadData', 'AppendData') }
	        }
            Write-Verbose -Message ('[{0}] Converted permission <{1}> to internal set <{2}>' -f $MyInvocation.MyCommand, $PermissionSetName, ($Permission -join ','))

	        if ($EnableInheritance) {
		        $Inheritance = ('ContainerInherit', 'ObjectInherit')
	        }
            Write-Verbose -Message ('[{0}] Using the following inheritance setting <{1}>' -f $MyInvocation.MyCommand, ($Inheritance -join ';'))
        }
        $Permission  = $Permission -join ','
        $Inheritance = $Inheritance -join ','
    
        try {
            Write-Verbose -Message ('[{0}] Creating new ACE rule for group <{1}>' -f $MyInvocation.MyCommand, $Group)
	        $Ace = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Group, $Permission, $Inheritance, 'None', 'Allow'

            Write-Verbose -Message ('[{0}] Reading existing ACLs for path <{1}>' -f $MyInvocation.MyCommand, $Path)
	        $Acl = Get-Acl -Path $Path

            if ($Acl.Access | Where-Object { $_.IdentityReference -ieq $Group }) {
                Write-Verbose -Message ('[{0}] Modifying existing permission rule' -f $MyInvocation.MyCommand)
			    $Modification = New-Object -TypeName System.Security.AccessControl.AccessControlModification
			    $Modification.value__ = 2
			    $Modified = $false
                $Acl.ModifyAccessRule($Modification, $Ace, [ref]$Modified) | Out-Null

            } else {
                Write-Verbose -Message ('[{0}] Adding rule to existing permissions' -f $MyInvocation.MyCommand)
                $Acl.AddAccessRule($Ace)
            }

            Write-Verbose -Message ('[{0}] Writing ACL to original path' -f $MyInvocation.MyCommand)
	        Set-Acl -Path $Path -AclObject $Acl

        } catch {
            Write-Verbose -Message ('[{0}] Failed to modify permissions' -f $MyInvocation.MyCommand)
            return $false
        }

	    Write-Verbose -Message ('[{0}] Done' -f $MyInvocation.MyCommand)
        return $true
    }
}

function Get-DirectoryContext {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.DirectoryContext])]
    param(
        [Parameter()]
        [ValidateSet('Forest', 'Domain')]
        [string]
        $ContextType = 'Forest'
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    Process {
        $Params = @($ContextType, $Name)
        if ($Credential) {
            $params += $Credential.UserName, $Credential.GetNetworkCredential().Password
        }
        New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList @($Params)
    }
}

function Get-Forest {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.Forest])]
    param(
        [Parameter(ValueFromPipeline, ParameterSetName='Context')]
        [ValidateNotNull()]
        [System.DirectoryServices.ActiveDirectory.DirectoryContext]
        $Context
        ,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='ForestName')]
        [ValidateNotNull()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='ForestName')]
        [ValidateNotNull()]
        [pscredential]
        $Credential
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'ForestName') {
            $Param = @{
                ContextType = 'Forest'
                Name        = $Name
            }
            if ($Credential) {
                $Param.Add('Credential', $Credential)
            }
            $Context = Get-DirectoryContext @Param
        }

        if ($Context -and $Context.ContextType -ine 'Forest') {
            throw 'Context type must be "Forest"'
        }

        if ($Context) {
            [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($Context)

        } else {
            [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        }
    }
}

function Get-Domain {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.Domain])]
    param(
        [Parameter(ValueFromPipeline, ParameterSetName='Context')]
        [ValidateNotNull()]
        [System.DirectoryServices.ActiveDirectory.DirectoryContext]
        $Context
        ,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='DomainName')]
        [ValidateNotNull()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='DomainName')]
        [ValidateNotNull()]
        [pscredential]
        $Credential
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'DomainName') {
            $Param = @{
                ContextType = 'Domain'
                DomainName  = $Name
            }
            if ($Credential) {
                $Param.Add('Credential', $Credential)
            }
            $Context = Get-DirectoryContext @Param
        }

        if ($Context -and $Context.ContextType -ine 'Domain') {
            throw 'Context type must be "Domain"'
        }

        if ($Context) {
            [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($Context)

        } else {
            [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        }
    }
}

function Get-TrustRelationship {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.TrustRelationshipInformationCollection])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $Forest
        ,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='ForestName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ForestName
        ,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $Domain
        ,
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName='DomainName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $Instance = $Forest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $Instance = $Domain
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestName') {
            $Instance = Get-DirectoryContext -ContextType Forest -Name $ForestName | Get-Forest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainName') {
            $Instance = Get-DirectoryContext -ContextType Domain -Name $DomainName | Get-Domain
        }
        
        $Instance.GetAllTrustRelationships()
    }
}

function New-TrustRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $SourceForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $DestinationForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $SourceDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceDomainName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $DestinationDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationDomainName
        ,
        [Parameter()]
        [ValidateSet('Inbound', 'Outbound', 'Bidirectional')]
        [string]
        $Direction = 'Bidirectional'
        ,
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Password
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'ForestName') {
            New-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForest (Get-Forest -Name $DestinationForestName) -Direction $Direction
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainName') {
            New-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomain (Get-Domain -Name $DestinationDomainName) -Direction $Direction
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestNameLocalSide') {
            New-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForestName $DestinationForestName -Direction $Direction -Password $Password
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainNameLocalSide') {
            New-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomainName $DestinationDomainName -Direction $Direction -Password $Password
            return
        }

        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $SourceInstance = $SourceForest
            $DestinationInstance = $DestinationForest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $SourceInstance = $SourceDomain
            $DestinationInstance = $DestinationDomain

        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestLocalSide') {
            $SourceInstance = $SourceForest
            $DestinationInstanceName = $DestinationForestName

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainLocalSide') {
            $SourceInstance = $SourceDomain
            $DestinationInstanceName = $DestinationDomainName
        }

        if ($Password) {
            $SourceInstance.CreateLocalSideOfTrustRelationship($DestinationInstanceName, $Direction, $Password)

        } else {
            $SourceInstance.CreateTrustRelationship($DestinationInstance, $Direction)
        }
    }
}

function Remove-TrustRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $SourceForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $DestinationForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $SourceDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceDomainName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $DestinationDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationDomainName
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'ForestName') {
            Remove-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForest (Get-Forest -Name $DestinationForestName)
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainName') {
            Remove-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomain (Get-Domain -Name $DestinationDomainName)
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestNameLocalSide') {
            Remove-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForestName $DestinationForestName
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainNameLocalSide') {
            Remove-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomainName $DestinationDomainName
            return
        }

        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $SourceInstance = $SourceForest
            $DestinationInstance = $DestinationForest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $SourceInstance = $SourceDomain
            $DestinationInstance = $DestinationDomain

        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestLocalSide') {
            $SourceInstance = $SourceForest
            $DestinationInstanceName = $DestinationForestName

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainLocalSide') {
            $SourceInstance = $SourceDomain
            $DestinationInstanceName = $DestinationDomainName
        }

        if (@('ForstLocalSide', 'DomainLocalSide') -icontains $PSCmdlet.ParameterSetName) {
            $SourceInstance.DeleteLocalSideOfTrustRelationship($DestinationInstanceName, $Direction, $Password)

        } elseif (@('Forest', 'Domain') -icontains $PSCmdlet.ParameterSetName) {
            $SourceInstance.DeleteTrustRelationship($DestinationInstance)
        }
        
    }
}

function Update-TrustRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $SourceForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $DestinationForest
        ,
        [Parameter(Mandatory, ParameterSetName='ForestName')]
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $SourceDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceDomainName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $DestinationDomain
        ,
        [Parameter(Mandatory, ParameterSetName='DomainName')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationDomainName
        ,
        [Parameter()]
        [ValidateSet('Inbound', 'Outbound', 'Bidirectional')]
        [string]
        $Direction = 'Bidirectional'
        ,
        [Parameter(Mandatory, ParameterSetName='ForestLocalSide')]
        [Parameter(Mandatory, ParameterSetName='ForestNameLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainLocalSide')]
        [Parameter(Mandatory, ParameterSetName='DomainNameLocalSide')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Password
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'ForestName') {
            Update-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForest (Get-Forest -Name $DestinationForestName) -Direction $Direction
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainName') {
            Update-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomain (Get-Domain -Name $DestinationDomainName) -Direction $Direction
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestNameLocalSide') {
            Update-TrustRelationship -SourceForest (Get-Forest -Name $SourceForestName) -DestinationForestName $DestinationForestName -Direction $Direction -Password $Password
            return

        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainNameLocalSide') {
            Update-TrustRelationship -SourceDomain (Get-Domain -Name $SourceDomainName) -DestinationDomainName $DestinationDomainName -Direction $Direction -Password $Password
            return
        }

        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $SourceInstance = $SourceForest
            $DestinationInstance = $DestinationForest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $SourceInstance = $SourceDomain
            $DestinationInstance = $DestinationDomain
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'ForestLocalSide') {
            $SourceInstance = $SourceDomain
            $DestinationInstanceName = $DestinationDomainName
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'DomainLocalSide') {
            $SourceInstance = $SourceDomain
            $DestinationInstanceName = $DestinationDomainName
        }

        if (@('ForstLocalSide', 'DomainLocalSide') -icontains $PSCmdlet.ParameterSetName) {
            $SourceInstance.UpdateLocalSideOfTrustRelationship($DestinationInstanceName, $Direction, $Password)

        } elseif (@('Forest', 'Domain') -icontains $PSCmdlet.ParameterSetName) {
            $SourceInstance.UpdateTrustRelationship($DestinationInstance, $Direction)
        }
    }
}

function Assert-TrustRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $SourceForest
        ,
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $DestinationForest
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $SourceDomain
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $DestinationDomain
        ,
        [Parameter(Mandatory)]
        [ValidateSet('Inbound', 'Outbound', 'Bidirectional')]
        [string]
        $Direction
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $SourceInstance = $SourceForest
            $DestinationInstance = $DestinationForest
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $SourceInstance = $SourceDomain
            $DestinationInstance = $DestinationDomain
        }

        $SourceInstance.VerifyTrustRelationship($DestinationInstance, $Direction)
    }
}

function Select-TrustRelationship {
    [CmdletBinding()]
    [OutputType([System.DirectoryServices.ActiveDirectory.TrustRelationshipInformation])]
    param(
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Forest]
        $SourceForest
        ,
        [Parameter(Mandatory, ParameterSetName='Forest')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationForestName
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [System.DirectoryServices.ActiveDirectory.Domain]
        $SourceDomain
        ,
        [Parameter(Mandatory, ParameterSetName='Domain')]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationDomainName
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'Forest') {
            $SourceInstance = $SourceForest
            $DestinationName = $DestinationForestName
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'Domain') {
            $SourceInstance = $SourceDomain
            $DestinationName = $DestinationDomainName
        }

        $SourceInstance.GetTrustRelationship($DestinationName)
    }
}