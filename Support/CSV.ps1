function Import-Array {
    [CmdletBinding()]
    [OutputType([System.Array])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $File
    )

    Write-Verbose ('[{0}] Sourcing from first existing input file' -f $MyInvocation.MyCommand)

    # check for input files in the following order
    foreach ($InputFile in $File) {
        Write-Verbose ('[{0}] Checking for input file <{1}>' -f $MyInvocation.MyCommand, $InputFile)

        # expand path to input file
        $InputFile = Join-Path -Path $PSScriptRoot -ChildPath $InputFile
        Write-Verbose ('[{0}] Full path to input file is <{1}>' -f $MyInvocation.MyCommand, $InputFile)

        # check if file exists
        if (Test-Path -Path $InputFile) {
            # jump out of loop because file exists
            Write-Verbose ('[{0}] Found file <{1}>. Skipping other candidates.' -f $MyInvocation.MyCommand, $InputFile)
            break
        }
        Write-Verbose ('[{0}] File <{1}> not found.' -f $MyInvocation.MyCommand, $InputFile)
    }

    # make sure an input file was found
    if ($InputFile -eq $null -Or -Not (Test-Path -Path $InputFile)) {
        throw ('[{0}] Unable to determine input file. Aborting.' -f $MyInvocation.MyCommand)
    }

    # read group memberships from file
    $Lines = @(Get-Content -Path $InputFile)
    Write-Verbose ('[{0}] Read {1} lines from input file <{2}>.' -f $MyInvocation.MyCommand, $Lines.Count, $InputFile)

    return $Lines
}

function Import-Hash {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $File
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Delimiter = ';'
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Header
    )

    Write-Verbose ('[{0}] Sourcing hash from first existing input file' -f $MyInvocation.MyCommand)

    # check for input files in the following order
    foreach ($InputFile in $File) {
        Write-Verbose ('[{0}] Checking for input file <{1}>' -f $MyInvocation.MyCommand, $InputFile)

        # expand path to input file
        $InputFile = Join-Path -Path $PSScriptRoot -ChildPath $InputFile
        Write-Verbose ('[{0}] Full path to input file is <{1}>' -f $MyInvocation.MyCommand, $InputFile)

        # check if file exists
        if (Test-Path -Path $InputFile) {
            # jump out of loop because file exists
            Write-Verbose ('[{0}] Found file <{1}>. Skipping other candidates.' -f $MyInvocation.MyCommand, $InputFile)
            break
        }
        Write-Verbose ('[{0}] File <{1}> not found.' -f $MyInvocation.MyCommand, $InputFile)
    }

    # make sure an input file was found
    if ($InputFile -eq $null -Or -Not (Test-Path -Path $InputFile)) {
        throw ('[{0}] Unable to determine input file. Aborting.' -f $MyInvocation.MyCommand)
    }

    # read hash from file
                        $params = @{}
    if ($Delimiter) {   $params.Add('Delimiter', $Delimiter) }
    if ($Header)    {   $params.Add('Header',    $Header) }
    Get-Content -Path $InputFile
    #[hashtable]$Hash = @{}
    $Hash = Get-Content -Path $InputFile | ConvertFrom-Csv @params
    Write-Verbose $Hash.GetType()
    Write-Verbose ('[{0}] Read {1} tenants from file <{2}>.' -f $MyInvocation.MyCommand, $Hash.Count, $InputFile)

    $Hash
}