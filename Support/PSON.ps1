function Get-Hashtable {
    # Taken from: https://github.com/PowerShellOrg/DSC/blob/development/Tooling/DscConfiguration/Get-Hashtable.ps1
    # Path to PSD1 file to evaluate
    param (
        [parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string]
        $Path
    )

    Process {
        # This code is duplicated in the DscBuild module's Import-DataFile function.
        # I don't really want to create any coupling between those two modules, but maybe
        # we can extract some common code into a utility module that's leveraged by both,
        # at some point.

        Write-Verbose -Message "Loading data from $Path."

        try {
            $content = Get-Content -Path $Path -Raw -ErrorAction Stop
            $scriptBlock = [scriptblock]::Create($content)

            [string[]] $allowedCommands = @(
                'Import-LocalizedData', 'ConvertFrom-StringData', 'Write-Host', 'Out-Host', 'Join-Path'
            )

            [string[]] $allowedVariables = @('PSScriptRoot')

            $scriptBlock.CheckRestrictedLanguage($allowedCommands, $allowedVariables, $true)

            return & $scriptBlock

        } catch {
            throw
        }
    }
}

function ConvertFrom-Pson {
    <#
    .SYNOPSIS
    Import a data structure in PowerShell Object Notation

    .DESCRIPTION
    XXX

    .PARAMETER Path
    Path of input file

    .EXAMPLE
    ConvertFrom-Pson -Path .\data.psd1

    .NOTES
    XXX
    #>
    [CmdletBinding()]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Write-Verbose -Message ('[{0}] Processing file <{1}>' -f $MyInvocation.MyCommand, $Path)
    if (Test-Path -Path $Path) {
        Write-Verbose -Message ('[{0}] Input file exists' -f $MyInvocation.MyCommand)

        <#$content = Get-Content -Path $Path -Raw
        Write-Verbose -Message ('[{0}] Obtained {1} bytes of input data' -f $MyInvocation.MyCommand, $content.Length)

        $data = Invoke-Expression -Command $content#>
        $data = Get-Hashtable -Path $Path
        Write-Verbose -Message ('[{0}] Converted input data to type {1}' -f $MyInvocation.MyCommand, $data.GetType().BaseType)

        return $data
    }

    throw ('[{0}] Input file does not exist. Aborting.' -f $MyInvocation.MyCommand)

    return
}