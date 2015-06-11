function Set-Credential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$CredentialName.clixml"
    }
    if (-not (Test-Path -Path $Path)) {
        throw ('Credential file {0} not found. Aborting.' -f $Path)
    }
    $Credential = Import-Clixml -Path $Path

    $PSDefaultParameterValues.'Invoke-Command:Credential'   = $Credential
    $PSDefaultParameterValues.'Enter-PSSession:Credential'  = $Credential
    $PSDefaultParameterValues.'New-PSSession:Credential'    = $Credential
    $PSDefaultParameterValues.'New-CimSession:Credential'   = $Credential
    $PSDefaultParameterValues.'Invoke-CimMethod:Credential' = $Credential
    $PSDefaultParameterValues.'New-CimInstance:Credential'  = $Credential
}

function Clear-Credential {
    [CmdletBinding()]
    param()

    $PSDefaultParameterValues.'Invoke-Command:Credential'   = $null
    $PSDefaultParameterValues.'Enter-PSSession:Credential'  = $null
    $PSDefaultParameterValues.'New-PSSession:Credential'    = $null
    $PSDefaultParameterValues.'New-CimSession:Credential'   = $null
    $PSDefaultParameterValues.'Invoke-CimMethod:Credential' = $null
    $PSDefaultParameterValues.'New-CimInstance:Credential'  = $null
}

function Set-PSSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$CredentialName.clixml"
    }
    if (-not (Test-Path -Path $Path)) {
        throw ('Credential file {0} not found. Aborting.' -f $Path)
    }
    $Credential = Import-Clixml -Path $Path

    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential

    Get-Command -ParameterType PSSession -ParameterName Session | Select-Object -ExpandProperty Name | ForEach-Object {
        $PSDefaultParameterValues."$_:Session" = $Session
    }
}

function Clear-PSSession {
    [CmdletBinding()]
    param()

    Get-Command -ParameterType PSSession -ParameterName Session | Select-Object -ExpandProperty Name | ForEach-Object {
        $PSDefaultParameterValues."$_:Session" = $null
    }
}

function Set-CimSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$true,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$CredentialName.clixml"
    }
    if (-not (Test-Path -Path $Path)) {
        throw ('Credential file {0} not found. Aborting.' -f $Path)
    }
    $Credential = Import-Clixml -Path $Path

    $CimSession = New-CimSession -ComputerName $ComputerName -Credential $Credential

    Get-Command -ParameterName CimSession | Select-Object -ExpandProperty Name | ForEach-Object {
        $PSDefaultParameterValues."$_:CimSession" = $CimSession
    }
}

function Clear-CimSession {
    [CmdletBinding()]
    param()

    Get-Command -ParameterName CimSession | Select-Object -ExpandProperty Name | ForEach-Object {
        $PSDefaultParameterValues."$_:CimSession" = $null
    }
}