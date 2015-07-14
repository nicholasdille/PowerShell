function New-HashFromArrays {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Keys
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Values
    )

    $hash = @{}
    for ($index = 0; $index -lt $Keys.Count; ++$index) {
        $hash[$Keys[$index]] = $Values[$index]
    }
    $hash
}

function ConvertTo-Hash {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Array
        ,
        [Parameter(Mandatory)]
        $Value = $null
    )

    BEGIN {
        $hash = @{}
    }

    PROCESS {
        foreach ($item in $Array) {
            if ($item -ne $null -And $item -ne '') {
                $hash[$item] = $Value;
            }
        }
    }

    END {
        $hash
    }
}