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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Write-Verbose ('[{0}] Processing file <{1}>' -f $MyInvocation.MyCommand, $Path)
    if (Test-Path -Path $Path) {
        Write-Verbose ('[{0}] Input file exists' -f $MyInvocation.MyCommand)

        $content = Get-Content -Path $Path -Raw
        Write-Verbose ('[{0}] Obtained {1} bytes of input data' -f $MyInvocation.MyCommand, $content.Length)

        $data = Invoke-Expression -Command $content
        Write-Verbose ('[{0}] Converted input data to type {1}' -f $MyInvocation.MyCommand, $data.GetType().BaseType)

        return $data
    }

    Write-Error ('[{0}] Input file does not exist. Aborting.' -f $MyInvocation.MyCommand)

    return
}