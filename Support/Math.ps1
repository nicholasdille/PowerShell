function Measure-Array {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $InputObject
    )

    BEGIN {
        $result = @{
            min = $null
            max = $null
            avg = $null
            sum = 0
            cnt = 0
        }
    }

    PROCESS {
        foreach ($item in $InputObject) {
            $result.cnt++
            $result.sum += $item

            #Write-Host "min=$($result.min)"
            if ($result.min -eq $null -or $item -lt $result.min) {
                #Write-Host -Message "min before=$($result.min) after=$item"
                $result.min = $item
            }

            #Write-Host "max=$($result.max)"
            if ($result.max -eq $null -or $item -gt $result.max) {
                #Write-Host -Message "max before=$($result.max) after=$item"
                $result.max = $item
            }
        }
    }

    END {
        $result.avg = $result.sum / $result.cnt
        [PSCustomObject]$result
    }
}

function ConvertTo-Histogram {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [int[]]
        $InputObject
        ,
        [Parameter(Mandatory=$true,ParameterSetName='BucketCount')]
        [ValidateNotNullOrEmpty()]
        [int]
        $BucketCount
        ,
        [Parameter(Mandatory=$true,ParameterSetName='BucketSize')]
        [ValidateNotNullOrEmpty()]
        [float]
        $BucketSize
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [float]
        $Minimum
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [float]
        $Maximum
    )

    BEGIN {
        $BucketLimits = @()
        $Buckets = @()

        if ($PSCmdlet.ParameterSetName -eq 'BucketSize') {
            $BucketCount = ($Maximum -  $Minimum) / $BucketSize

        } elseif ($PSCmdlet.ParameterSetName -eq 'BucketCount') {
            $BucketSize = ($Maximum - $Minimum) / $BucketCount
        }

        Write-Verbose -Message ('[{0}] Initilized bucket count <{1}> and bucket size <{2}>' -f $MyInvocation.MyCommand, $BucketCount, $BucketSize)

        for ($BucketIndex = 0; $BucketIndex -lt $BucketCount; ++$BucketIndex) {
            $Buckets += ,@(0)
            
            if ($BucketIndex -eq 0) {
                $BucketLimits = @($Minimum)
            } else {
                $BucketLimits += @($BucketLimits[$BucketIndex - 1])
            }
            $BucketLimits[$BucketIndex] += $BucketSize
        }
    }

    PROCESS {
        foreach ($item in $InputObject) {
            $BucketIndex = 0
            while ($item -gt $BucketLimits[$BucketIndex]) {
                ++$BucketIndex
            }
            $Buckets[$BucketIndex] += 1
        }
    }

    END {
        New-HashFromArrays -Keys $BucketLimits -Values $Buckets
    }
}

function Convert-HistogramToRelative {}
function New-DistributionFromHistogram {}
function Convert-DistributionToRelative {}