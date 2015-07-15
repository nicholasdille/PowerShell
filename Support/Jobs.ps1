function Invoke-Queue {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Job[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $InputObject
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $Scriptblock
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $ArgumentList
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $ThrottleLimit = 32
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $Delay = 2
    )

    Begin {
        Write-Verbose -Message ('[{0}] Initializing variables' -f $MyInvocation.MyCommand)
        $Jobs = @()
        $InputIndex = 0

        Write-Verbose -Message ('[{0}] Processing {1} objects' -f $MyInvocation.MyCommand, $InputObject.Count)
    }

    Process {
        while ($InputIndex -lt $InputObject.Count) {
            Write-Debug -Message ('[{0}] InputIndex={1} JobCount={2} RunningJobCount={3}' -f $MyInvocation.MyCommand, $InputIndex, $Jobs.Count, ($Jobs | Get-Job | Where-Object {$_.State -ieq 'Running'}).Count)

            if ($Jobs.Count -lt $ThrottleLimit -or ($Jobs | Get-Job | Where-Object {$_.State -ieq 'Running'}).Count -lt $ThrottleLimit) {
                Write-Verbose -Message ('[{0}] New job for parameter index {1}' -f $MyInvocation.MyCommand, $InputIndex)
                $Jobs += Start-Job -ScriptBlock $Scriptblock -Name $InputObject[$InputIndex].ToString() -ArgumentList (@($InputObject[$InputIndex]) + $ArgumentList)

                ++$InputIndex

            } else {
                Start-Sleep -Seconds $Delay
            }
        }

        Write-Verbose -Message ('[{0}] All input objects are being processed' -f $MyInvocation.MyCommand)
        $Jobs
    }
}