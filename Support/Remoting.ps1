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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName = $env:COMPUTERNAME
        ,
        [Parameter()]
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
        [Parameter(Mandatory,ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(ParameterSetName='Computer')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory,ParameterSetName='PsSession')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $VmName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Files
        ,
        [Parameter(Mandatory)]
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory)]
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourcePath
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory)]
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

function Import-RemoteModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ModuleName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Prefix
        ,
        [Parameter(Mandatory,ParameterSetName='ComputerName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(ParameterSetName='ComputerName')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(ParameterSetName='Session')]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
    )

    Process {
        if ($PSCmdlet.ParameterSetName -ieq 'ComputerName') {
            Write-Verbose -Message ('[{0}] Creating session to {1}' -f $MyInvocation.MyCommand, $ComputerName)
            $SessionParameters = @{
                ComputerName = $ComputerName
            }
            if ($Credential) {
                Write-Verbose -Message ('[{0}] Using credentials' -f $MyInvocation.MyCommand)
                $SessionParameters.Add('Credential', $Credential)
            }
            $Session = New-PSSession @SessionParameters
        }

        Write-Verbose -Message ('[{0}] Loading module {1} in remote session' -f $MyInvocation.MyCommand, $ModuleName)
        Invoke-Command -Session $Session -ScriptBlock {
            Import-Module -Name $Using:ModuleName
        }

        Write-Verbose -Message ('[{0}] Importing module {1} from remote session with prefix {2}' -f $MyInvocation.MyCommand, $ModuleName, $Prefix)
        $RemoteModule = Import-PSSession -Session $Session -Module $ModuleName -Prefix $Prefix -AllowClobber -FormatTypeName *

        Write-Verbose -Message ('[{0}] Loading remote module {1} in local session' -f $MyInvocation.MyCommand, $ModuleName)
        Import-Module -Name $RemoteModule -Global

        Write-Verbose -Message ('[{0}] Done' -f $MyInvocation.MyCommand)
    }
}