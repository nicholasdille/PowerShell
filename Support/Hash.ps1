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
            if ($item) {
                $hash[$item] = $Value;
            }
        }
    }

    END {
        $hash
    }
}

function ConvertFrom-KeyValueString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $InputObject
    )

    Begin {
        $Data = @{}
    }

    Process {
        foreach ($Line in $InputObject) {
            if ($Line -imatch '^([^=]+)=(.*)$') {
                $Data.Add($Matches[1], $Matches[2])
            
            } else {
                Write-Error -Message ('[{0}] Mangled input line: <{1}>' -f $MyInvocation.MyCommand, $Line)
            }
        }
    }

    End {
        $Data
    }
}