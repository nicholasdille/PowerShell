function Get-CredentialFromStore {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER CredentialName
    XXX

    .PARAMETER CredentialStore
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType([pscredential])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialStore
    )

    $Path = Join-Path -Path $CredentialStore -ChildPath ($CredentialName + '.clixml')
    Import-Clixml -Path $Path
}

function New-CredentialInStore {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER CredentialName
    XXX

    .PARAMETER Credential
    XXX

    .PARAMETER CredentialStore
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialStore
    )

    $Path = Join-Path -Path $CredentialStore -ChildPath ($CredentialName + '.clixml')
    $Credential | Export-Clixml -Path $Path
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $CredentialName
        ,
        [Parameter()]
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
        [Parameter(ParameterSetName='Computer')]
        [switch]
        $UseCredSsp
        ,
        [Parameter(Mandatory,ParameterSetName='PsSession')]
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter()]
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

function Test-Credential {
    <#
    .SYNOPSIS
    Takes a PSCredential object and validates it against the domain (or local machine, or ADAM instance).

    .PARAMETER Credential
    A PSCredential object with the username/password you wish to test. Typically this is generated using the Get-Credential cmdlet. Accepts pipeline input.

    .PARAMETER Context
    An optional parameter specifying what type of Credential this is. Possible values are 'Domain','Machine',and 'ApplicationDirectory.' The default is 'Domain.'

    .OUTPUTS
    A boolean, indicating whether the Credentials were successfully validated.
    #>

    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter()]
        [ValidateSet('Domain', 'Machine', 'ApplicationDirectory')]
        [string]
        $Context = 'Domain'
    )

    Begin {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $DS = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgmentList [System.DirectoryServices.AccountManagement.ContextType]::$Context
    }

    Process {
        $DS.ValidateCredentials($Credential.UserName, $Credential.GetNetworkCredential().Password)
    }
}