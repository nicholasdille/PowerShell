function Convert-RemoteFilePath {
    <#
    .SYNOPSIS
    Convert a file path to UNC

    .PARAMETER FilePath
    Path to a local file

    .PARAMETER ComputerName
    Computer name used in the UNC path (defaults to $Env:ComputerName)

    .PARAMETER DomainName
    Domain name used in the UNC path (defaults to $Env:UserDnsDomain)

    .EXAMPLE
    Convert-RemoteFilePath -FilePath c:\Windows\System32\cmd.exe
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName = $env:COMPUTERNAME
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName = $env:USERDNSDOMAIN
    )

    $FilePath -imatch '^(\w)\:\\' | Out-Null
    $FilePath.Replace($Matches[0], '\\' + $ComputerName + '.' + $DomainName + '\' + $Matches[1] + '$\')
}

function Copy-VMFileRemotely {
    <#
    .SYNOPSIS
    Transfers a file to a virtual machine

    .DESCRIPTION
    This function uses the guest service integration to transfer the file. The transfer is initiated on the Hyper-V host

    .PARAMETER ComputerName
    Hyper-V host

    .PARAMETER CredentialName
    Name of credential

    .PARAMETER Session
    Session configuration for connecting to Hyper-V host

    .PARAMETER VmName
    Name of the VM to receive the files

    .PARAMETER Files
    Array of files to transfer into the VM

    .PARAMETER DestinationPath
    Destination path inside the VM

    .EXAMPLE
    Copy-VMFileRemotely -ComputerName hv-01 -CredentialName 'administrator@example.com' -VmName DSC-01 -Files (gci .) -DestinationPath c:\dsc

    .NOTES
    This cmdlet relys on the credential cmdlets of this module and requires CredSSP to be configured on the Hyper-V host if the source files reside on a file share
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$false,ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory=$true,ParameterSetName='PsSession')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $VmName
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Files
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
    )

    if (-Not $Session) {
        $params = @{
            ComputerName   = $ComputerName
            CredentialName = $CredentialName
            UseCredSsp     = $True
        }
        $Session = New-PsRemoteSession @params
    }

    Invoke-Command -Session $Session -ScriptBlock {
        foreach ($File in $Using:Files) {
            Copy-VMFile $Using:VmName -SourcePath $File -DestinationPath $Using:DestinationPath -CreateFullPath -FileSource Host -Force
        }
    }
}

function New-PsRemoteSession {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER ComputerName
    Hyper-V host

    .PARAMETER CredentialName
    Name of credential

    .PARAMETER UseCredSsp
    Whether the connection uses CredSSP

    .EXAMPLE
    New-PsRemoteSession -ComputerName hv-01

    .EXAMPLE
    New-PsRemoteSession -ComputerName hv-01 -CredentialName 'administrator@example.com'

    .EXAMPLE
    New-PsRemoteSession -ComputerName hv-01 -CredentialName 'administrator@example.com' -UseCredSsp

    .NOTES
    This cmdlet relys on the credential cmdlets of this module
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Runspaces.PSSession])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $UseCredSsp
    )

    if ($UseCredSsp -And -Not $CredentialName) {
        throw ('[{0}] When using CredSSP credentials must be specified. Aborting.' -f $MyInvocation.MyCommand)
    }

    $params = @{}
                           $params.Add('ComputerName',    $ComputerName)
    if ($CredentialName) { $params.Add('Credential',      (Get-CredentialFromStore -CredentialName $CredentialName)) }
    if ($UseCredSsp)     { $params.Add('Authentication', 'Credssp') }

    $Session = New-PSSession @params
    if (-Not $Session) {
        throw ('[{0}] Failed to create PowerShell remote session to <{1}>. Aborting.' -f $MyInvocation.MyCommand, $ComputerName)
    }

    $Session
}

function Enter-PsRemoteSession {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER ComputerName
    Hyper-V host

    .PARAMETER CredentialName
    Name of credential

    .PARAMETER UseCredSsp
    Whether the connection uses CredSSP

    .PARAMETER Session
    XXX

    .EXAMPLE
    Enter-PsRemoteSession -ComputerName hv-01

    .EXAMPLE
    Enter-PsRemoteSession -ComputerName hv-01 -CredentialName 'administrator@example.com'

    .EXAMPLE
    Enter-PsRemoteSession -ComputerName hv-01 -CredentialName 'administrator@example.com' -UseCredSsp

    .EXAMPLE
    Enter-PsRemoteSession -Session $session

    .NOTES
    This cmdlet relys on the credential cmdlets of this module
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$false,ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory=$false,ParameterSetName='Computer')]
        [switch]
        $UseCredSsp
        ,
        [Parameter(Mandatory=$true,ParameterSetName='PsSession')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
    )

    if (-Not $Session) {
        $Session = New-PsRemoteSession @PSBoundParameters
    }
    Enter-PSSession -Session $Session
}

function New-SimpleCimSession {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER ComputerName
    Hyper-V host

    .PARAMETER CredentialName
    Name of credential

    .EXAMPLE
    New-SimpleCimSession -ComputerName hv-01

    .EXAMPLE
    New-SimpleCimSession -ComputerName hv-01 -CredentialName 'administrator@example.com'

    .NOTES
    This cmdlet relys on the credential cmdlets of this module
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimSession])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
    )

    $params = @{}
                           $params.Add('ComputerName',    $ComputerName)
    if ($CredentialName) { $params.Add('Credential',      (Get-CredentialFromStore -CredentialName $CredentialName)) }

    $CimSession = New-CimSession @params
    if (-Not $CimSession) {
        throw ('[{0}] Failed to create PowerShell remote session to <{1}>. Aborting.' -f $MyInvocation.MyCommand, $ComputerName)
    }

    $CimSession
}

function Copy-ToRemoteItem {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER SourcePath
    XXX

    .PARAMETER ComputerName
    XXX

    .PARAMETER DestinationPath
    XXX

    .PARAMETER Credential
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    $SourceData = Get-Content -Path $SourcePath -Encoding Byte
    $SourceDataBase64 = [System.Convert]::ToBase64String($SourceData)
    Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
        [System.Convert]::FromBase64String($Using:SourceDataBase64) | Set-Content -Path $Using:DestinationPath -Encoding Byte
    }
}

function Copy-FromRemoteItem {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER SourcePath
    XXX

    .PARAMETER ComputerName
    XXX

    .PARAMETER DestinationPath
    XXX

    .PARAMETER Credential
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    $SourceDataBase64 = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
        $SourceData = Get-Content -Path $Using:SourcePath -Encoding Byte
        [System.Convert]::ToBase64String($SourceData)
    }
    [System.Convert]::FromBase64String($SourceDataBase64) | Set-Content -Path $DestinationPath -Encoding Byte
}