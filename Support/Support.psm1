Set-StrictMode -Version Latest

function Get-PSVersion {
    <#
    .SYNOPSIS
    Returns the PowerShell version consistently across all versions

    .DESCRIPTION
    This function attempts to use PSVersionTable. This is unavailable in PowerShell 1.0, so forges the necessary output

    .EXAMPLE
    Get-PSVersion
    #>
    [CmdletBinding()]
    [OutputType([version])]
    param()

    if (Test-Path -Path Variable:\PSVersionTable) {
        $PSVersionTable.PSVersion

    } else {
        [version]'1.0.0.0'
    }
}

. (Join-Path -Path $PSScriptRoot -ChildPath 'Base64.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Credentials.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Remoting.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'SecureString.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Virtualization.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'CSV.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'ActiveDirectory.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'PSON.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'PsDrive.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'DefaultCredentials.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'PSDefaultParameterValues.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'File.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Hash.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Math.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'Networking.ps1')
