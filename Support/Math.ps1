function New-Histogram {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $InputObject
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [float]
        $Granularity
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [float]
        $Minimum
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [float]
        $Maximum
    )

    BEGIN {
        $BucketCount = ($Maximum -  $Minimum + 1) / $Granularity

        $BucketObjects = @(
            [pscustomobject]@{Index = 0; LowerLimit = $Granularity; Count = 0}
        )
        for ($BucketIndex = 1; $BucketIndex -lt $BucketCount; ++$BucketIndex) {
            $BucketObjects += ,[pscustomobject]@{
                Index      = $BucketIndex
                LowerLimit = $Granularity + $BucketIndex * $Granularity
                Count      = 0
            }
        }
    }

    PROCESS {
        foreach ($item in $InputObject) {
            $BucketIndex = [int]($item / $Granularity) - 1
            $BucketObjects[$BucketIndex].Count += 1
        }
    }

    END {
        $BucketObjects
    }
}

function ConvertTo-RelativeHistogram {
    [CmdletBinding()]
    param(
        #
    )

    #
}

function New-DistributionFromHistogram {}
function Convert-DistributionToRelative {}