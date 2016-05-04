Function Get-Account {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    [OutputType([System.Security.Principal.IdentityReference])]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='SecurityIdentifier', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.SecurityIdentifier]
        $SecurityIdentifier
        ,
        [Parameter(ParameterSetName='SddlShortName', Mandatory)]
        [ValidateSet('AO', 'AN', 'AU', 'BA', 'BG', 'BO', 'BU', 'CA', 'CG', 'CO', 'DA', 'DC', 'DD', 'DG', 'DU', 'EA', 'ED', 'WD', 'PA', 'IU', 'LA', 'LG', 'LS', 'SY', 'NU', 'NO', 'NS', 'PO', 'PS', 'PU', 'RS', 'RD', 'RE', 'RC', 'SA', 'SO', 'SU')]
        [string]
        $ShortName

    )

    Process {
        If ($PSCmdlet.ParameterSetName -ieq 'NTAccount') {
            $IdentityReference = New-Object System.Security.Principal.NTAccount $DomainName, $UserName
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'SecurityIdentifier') {
            $IdentityReference = $SecurityIdentifier
        
        } elseif ($PSCmdlet.ParameterSetName -ieq 'SddlShortName') {
            $IdentityReference = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $ShortName

        } else {
            throw ('[{0}] Unknown parameter set <{1}>' -f $MyInvocation.MyCommand, $PSCmdlet.ParameterSetName)
        }

        $IdentityReference
    }
}

Function Assert-Path {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Process {
        If (Test-Path -Path $Path) {
            Write-Verbose ('[{0}] Path <{1}> exists' -f $MyInvocation.MyCommand, $Path)

        } else {
            throw ('[{0}] Path <{1}> does not exist' -f $MyInvocation.MyCommand, $Path)
        }
    }
}

Function Set-Permission {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessRule]
        $Rule
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Acl = Get-Acl -Path $Path

        if ($Acl.Access | Where-Object { $_.IdentityReference.Value -ieq $Rule.IdentityReference.Value }) {
            $Modification = New-Object System.Security.AccessControl.AccessControlModification
            $Modification.value__ = 2
            $Modified = $false

            $null = $Acl.ModifyAccessRule($Modification, $Rule, [ref]$Modified)

        } else {
            $Acl.AddAccessRule($Rule)
        }

        Set-Acl -Path $Path -AclObject $Acl
    }
}

Function Set-FilesystemPermission {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.IdentityReference]
        $Account = (New-Object -TypeName System.Security.Principal.SecurityIdentifier('SY'))
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(AppendData, ChangePermissions, CreateDirectories, CreateFiles, Delete, DeleteSubdirectoriesAndFiles, ExecuteFile, FullControl, ListDirectory, Modify, Read, ReadAndExecute, ReadAttributes, ReadData, ReadExtendedAttributes, ReadPermissions, Synchronize, TakeOwnership, Traverse, Write, WriteAttributes, WriteData, WriteExtendedAttributes)]
        [System.Security.AccessControl.FileSystemRights]
        $Right = 'FullControl'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(None, ContainerInherit, ObjectInherit)]
        [System.Security.AccessControl.InheritanceFlags]
        $Inheritance = 'ContainerInherit'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(None, InheritOnly, NoPropagateInherit)]
        [System.Security.AccessControl.PropagationFlags]
        $Propagation = 'None'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]
        $Access = 'Allow'
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Account = New-Object System.Security.Principal.NTAccount $DomainName, $UserName

        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList $Account, $Right, $Inheritance, $Propagation, $Access

        Set-Permission -Path $Path -Rule $Rule
    }
}

Function Set-RegistryPermission {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.IdentityReference]
        $Account = (New-Object -TypeName System.Security.Principal.SecurityIdentifier('SY'))
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(ChangePermissions, CreateLink, CreateSubKey, Delete, EnumerateSubKeys, ExecuteKey, FullControl, Notify, QueryValues, ReadKey, ReadPermissions, SetValue, TakeOwnership, WriteKey)]
        [System.Security.AccessControl.RegistryRights]
        $Right = 'FullControl'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(None, ContainerInherit, ObjectInherit)]
        [System.Security.AccessControl.InheritanceFlags]
        $Inheritance = 'ContainerInherit'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(None, InheritOnly, NoPropagateInherit)]
        [System.Security.AccessControl.PropagationFlags]
        $Propagation = 'None'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]
        $Access = 'Allow'
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Account = New-Object System.Security.Principal.NTAccount $DomainName, $UserName

        $Rule = New-Object -TypeName System.Security.AccessControl.RegistryAccessRule -ArgumentList $Account, $Right, $Inheritance, $Propagation, $Access

        Set-Permission -Path $Path -Rule $Rule
    }
}

Function Set-ActiveDirectoryPermission {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.IdentityReference]
        $Account = (New-Object -TypeName System.Security.Principal.SecurityIdentifier('SY'))
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(AccessSystemSecurity, CreateChild, Delete, DeleteChild, DeleteTree, ExtendedRight, GenericAll, GenericExecute, GenericRead, GenericWrite, ListChildren, ListObject, ReadControl, ReadProperty, Self, Synchronize, WriteDacl, WriteOwner, WriteProperty)]
        [System.DirectoryServices.ActiveDirectoryRights]
        $Right = 'GenericAll'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateSet(All, None, Children, Descendents, SelfAndChildren)]
        [System.DirectoryServices.ActiveDirectorySecurityInheritance]
        $Inheritance = 'All'
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.AccessControl.AccessControlType]
        $Access = 'Allow'
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Account = New-Object System.Security.Principal.NTAccount $DomainName, $UserName

        $Rule = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $Account, $Right, $Access, $Inheritance

        Set-Permission -Path $Path -Rule $Rule
    }
}

Function Set-Owner {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.IdentityReference]
        $Account = (New-Object -TypeName System.Security.Principal.SecurityIdentifier('SY'))
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Acl = Get-Acl -Path $Path

        If ($PSCmdlet.PArameterSetName -ieq 'NTAccount') {
            $IdentityReference = New-Object System.Security.Principal.NTAccount $DomainName, $UserName
        }

        $Acl.SetOwner($IdentityReference)

        Set-Acl -Path $Path -AclObject $Acl
    }
}

Function Remove-Permission {
    [CmdletBinding(DefaultParameterSetName='NTAccount')]
    Param(
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName
        ,
        [Parameter(ParameterSetName='NTAccount', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $UserName
        ,
        [Parameter(ParameterSetName='IdentityReference', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Security.Principal.IdentityReference]
        $Account = (New-Object -TypeName System.Security.Principal.SecurityIdentifier('SY'))
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Acl = Get-Acl -Path $Path

        If ($PSCmdlet.PArameterSetName -ieq 'NTAccount') {
            $IdentityReference = New-Object System.Security.Principal.NTAccount $DomainName, $UserName
        }

        $Acl.PurgeAccessRules($IdentityReference)

        Set-Acl -Path $Path -AclObject $Acl
    }
}

Function Disable-Inheritance {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Begin {
        Assert-Path -Path $Path
    }

    Process {
        $Acl = Get-Acl -Path $Path
        $Ace = $Acl.Access

        $Acl.SetAccessRuleProtection($true, $false)
        $Ace | ForEach-Object {
            $ErrorActionPreference = 'SilentlyContinue'
            $Acl.AddAccessRule($_)
        }

        Set-Acl -Path $Path -AclObject $Acl
    }
}