function Set-Credential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$Name.clixml"
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
        [Parameter(Mandatory,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$Name.clixml"
    }
    if (-not (Test-Path -Path $Path)) {
        throw ('[{0}] Credential file {0} not found. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }
    $Credential = Import-Clixml -Path $Path
    if (-not $Credential) {
        throw ('[{0}] Failed to import credentials. Aborting' -f $MyInvocation.MyCommand)
    }

    $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
    if (-not $Session) {
        throw ('[{0}] Failed to create remote session. Aborting.' -f $MyInvocation.MyCommand)
    }
        
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
        [Parameter(Mandatory,ParameterSetName='CredentialName')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialFile')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory,ParameterSetName='CredentialObject')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
    )

    if ($PSCmdlet.ParameterSetName -ieq 'CredentialName') {
        $Path = Join-Path -Path $PSScriptRoot -ChildPath "$Name.clixml"
    }
    if (-not (Test-Path -Path $Path)) {
        throw ('Credential file {0} not found. Aborting.' -f $Path)
    }
    $Credential = Import-Clixml -Path $Path
    if (-not $Credential) {
        throw ('[{0}] Failed to import credentials. Aborting' -f $MyInvocation.MyCommand)
    }

    $CimSession = New-CimSession -ComputerName $ComputerName -Credential $Credential
    if (-not $CimSession) {
        throw ('[{0}] Failed to create CIM session. Aborting.' -f $MyInvocation.MyCommand)
    }

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