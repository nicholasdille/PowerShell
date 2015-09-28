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
        ,
        [switch]
        $Wait
        ,
        [switch]
        $ShowProgress
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ProgressActivityMessage = 'Processed input objects'
    )

    Begin {
        Write-Verbose ('[{0}] Initializing variables' -f $MyInvocation.MyCommand)
        $Jobs = @()
        $InputIndex = 0
        if ($Wait) {
            Write-Verbose ('[{0}] Setting <ThrottleLimit> to 1 because <Wait> was specified.' -f $MyInvocation.MyCommand)
            $ThrottleLimit = 1
        }

        Write-Verbose ('[{0}] Processing {1} objects' -f $MyInvocation.MyCommand, $InputObject.Count)
    }

    Process {
        while ($InputIndex -lt $InputObject.Count) {
            Write-Debug ('[{0}] InputIndex={1} JobCount={2} RunningJobCount={3}' -f $MyInvocation.MyCommand, $InputIndex, $Jobs.Count, ($Jobs | Get-Job | Where-Object {$_.State -ieq 'Running'}).Count)

            if ($Jobs.Count -lt $ThrottleLimit -or ($Jobs | Get-Job | Where-Object {$_.State -ieq 'Running'}).Count -lt $ThrottleLimit) {
                Write-Verbose ('[{0}] New job for parameter index {1}' -f $MyInvocation.MyCommand, $InputIndex)
                $Job = Start-Job -ScriptBlock $Scriptblock -Name $InputObject[$InputIndex].ToString() -ArgumentList (@($InputObject[$InputIndex]) + $ArgumentList)
                $Jobs += $Job
                Write-Progress -Activity $ProgressActivityMessage -Status "Invoked $($InputObject[$InputIndex].ToString())" -PercentComplete ($Jobs.Count / $InputObject.Count * 100)
                if ($Wait) {
                    Write-Output ('[{0}] Receiving output for job <{1}>' -f $MyInvocation.MyCommand, $Job.Name)
                    $Job | Receive-Job -Wait
                }

                ++$InputIndex

            } else {
                Write-Debug ('[{0}] Waiting for a job to finish' -f $MyInvocation.MyCommand)
                Start-Sleep -Seconds $Delay
            }
        }

        Write-Verbose ('[{0}] All input objects are being processed' -f $MyInvocation.MyCommand)
        Write-Progress -Activity $ProgressActivityMessage -Completed
        $Jobs
    }
}

function Install-WindowsUpdate {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Recommended')]
        [string]
        $Filter = 'Recommended'
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $ScanOnly
    )

    $ResultData = @{}

    $SearchString = @{
        'All'         = "IsInstalled=0 and Type='Software' and AutoSelectOnWebsites=1"
        'Recommended' = "IsInstalled=0 and Type='Software'"
    }
    
    $UpdateSession = New-Object -Com Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search($SearchString[$Filter])
    $ResultData.Add('UpdatesFound', $SearchResult.Updates.Count)
    if ($SearchResult.Updates.Count -eq 0) {
        Write-Verbose ('[{0}] No updates found' -f $MyInvocation.MyCommand)
        return $ResultData
    }

    if ($ScanOnly) {
        foreach ($Update in $SearchResult.Updates) {
            Write-Host $Update.Title
        }
        $ResultData.Add('ScanOnly', $ScanOnly)
        return $ResultData
    }

    $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
    foreach ($Update in $SearchResult.Updates) {
        Write-Verbose ('[{0}] Adding an update to the download list: {1}.' -f $MyInvocation.MyCommand, $Update.Title)
        $UpdatesToDownload.Add($Update) | Out-Null
    }
    $ResultData.Add('UpdatedToDownload', $UpdatesToDownload.Count)
    if ($UpdatesToDownload.Count -eq 0) {
        Write-Verbose ('[{0}] No updates found. Aborting.' -f $MyInvocation.MyCommand)
        return $ResultData
    }

    $Downloader = $UpdateSession.CreateUpdateDownloader()
    $Downloader.Updates = $UpdatesToDownload
    Write-Verbose ('[{0}] Downloading updates ...' -f $MyInvocation.MyCommand)
    $Downloader.Download()

    $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
    foreach ($Update in $SearchResult.Updates) {
        if ($Update.IsDownloaded) {
            Write-Verbose ('[{0}] Adding a downloaded update to the installation list: {1}.' -f $MyInvocation.MyCommand, $Update.Title)
            $UpdatesToInstall.Add($Update) | Out-Null
        }
    }
    $ResultData.Add('UpdatedToInstall', $UpdatesToInstall.Count)
    if ($UpdatesToInstall.Count -eq 0) {
        Write-Verbose ('[{0}] No updates downloaded. Aborting.' -f $MyInvocation.MyCommand)
        return $ResultData
    }

    $Installer = $UpdateSession.CreateUpdateInstaller()
    Write-Verbose ('[{0}] Installing Updates ...' -f $MyInvocation.MyCommand)
    $Installer.Updates = $UpdatesToInstall
    $InstallationResult = $Installer.Install()
    Write-Verbose ('[{0}] Installation completed' -f $MyInvocation.MyCommand)
    
    for ($i = 0; $i -lt $UpdatesToInstall.Count; ++$i) {
        $ResultData.Add($UpdatesToInstall.Item($i), $InstallationResult.GetUpdateResult($i).ResultCode)
    }
    $ResultData.Add('ResultCode', $InstallationResult.ResultCode)
    $ResultData.Add('RebootRequired', $InstallationResult.RebootRequired)
    $ResultData.Add('RebootInitiated', $false)

    Write-Verbose ('[{0}] Done' -f $MyInvocation.MyCommand)
    $ResultData
}

function ConvertTo-Progress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ProgressText
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $ParentId
    )

    Process {
        foreach ($Line in $ProgressText) {
            $ProgressParams = @{
                Activity          = '[UNKNOWN_ACTIVITY]'
                Status            = '[UNKNOWN_STATUS]'
                PercentComplete   = 0
            }
            if ($PSBoundParameters.ContainsKey('Id')) {
                $ProgressParams.Add('Id', $Id)
            }
            if ($PSBoundParameters.ContainsKey('ParentId')) {
                $ProgressParams.Add('ParentId', $ParentId)
            }

            $LineMatched = $false

            if ($Line -imatch 'Id=(\S+)') {
                $ProgressParams['Id'] = $Matches[1]
                $LineMatched = $true
            }
            if ($Line -imatch 'ParentId=(\S+)') {
                $ProgressParams['ParentId'] = $Matches[1]
                $LineMatched = $true
            }
            if ($Line -imatch 'Activity="([^"]+)"') {
                $ProgressParams['Activity'] = $Matches[1]
                $LineMatched = $true
            }
            if ($Line -imatch 'Operation="([^"]+)"') {
                $ProgressParams['CurrentOperation'] = $Matches[1]
                $LineMatched = $true
            }
            if ($Line -imatch 'Status="([^"]+)"') {
                $ProgressParams['Status'] = $Matches[1]
                $LineMatched = $true
            }
            if ($Line -imatch 'Percentage=(\S+)') {
                $ProgressParams['PercentComplete'] = $Matches[1]
                $LineMatched = $true
            }

            if ($LineMatched) {
                Write-Progress @ProgressParams

            } else {
                Write-Output $Line
            }
        }
    }
}

function Show-JobProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Job[]]
        $Job
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [scriptblock]
        $FilterScript
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $ParentId
        ,
        [Parameter()]
        [switch]
        $GenerateUniqueId
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $UniqueIdOffset = -1
    )

    Begin {
        $ActivityId = @{}

        if ($GenerateUniqueId -and $ParentId -and -not $UniqueIdOffset -gt -1) {
            $UniqueIdOffset = $ParentId
        }
    }

    Process {
        $Job.ChildJobs | ForEach-Object {
            if (-not $_.Progress) {
                return
            }

            $LastProgress = $_.Progress
            if ($FilterScript) {
                $LastProgress = $LastProgress | Where-Object -FilterScript $FilterScript
            }

            $LastProgress | Group-Object -Property Activity,StatusDescription | ForEach-Object {
                $_.Group | Select-Object -Last 1

            } | ForEach-Object {
                $ProgressParams = @{}
                if ($_.Activity          -and $_.Activity          -ne $null) { $ProgressParams.Add('Activity',         $_.Activity) }
                if ($_.StatusDescription -and $_.StatusDescription -ne $null) { $ProgressParams.Add('Status',           $_.StatusDescription) }
                if ($_.CurrentOperation  -and $_.CurrentOperation  -ne $null) { $ProgressParams.Add('CurrentOperation', $_.CurrentOperation) }
                if ($_.ActivityId        -and $_.ActivityId        -gt -1)    { $ProgressParams.Add('Id',               $_.ActivityId) }
                if ($_.ParentActivityId  -and $_.ParentActivityId  -gt -1)    { $ProgressParams.Add('ParentId',         $_.ParentActivityId) }
                if ($_.PercentComplete   -and $_.PercentComplete   -gt -1)    { $ProgressParams.Add('PercentComplete',  $_.PercentComplete) }
                if ($_.SecondsRemaining  -and $_.SecondsRemaining  -gt -1)    { $ProgressParams.Add('SecondsRemaining', $_.SecondsRemaining) }

                if ($ParentId) {
                    $ProgressParams['ParentId'] = $ParentId
                }

                if ($GenerateUniqueId) {
                    #$ActivityKey = '{0}@@@{1}' -f $_.Activity, $_.StatusDescription
                    $ActivityKey = $_.Activity

                    if (-not $ActivityId.ContainsKey($ActivityKey)) {
                        $NextId = $UniqueIdOffset + $ActivityId.Count + 1

                        $ActivityId.Add($ActivityKey, $NextId)
                    }

                    $ProgressParams['Id'] = $ActivityId[$ActivityKey]
                }

                Write-Progress @ProgressParams
            }
        }
    }
}