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

function Install-WindowsUpdate {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('All', 'Recommended')]
        [string]
        $Filter = 'Recommended'
        ,
        [Parameter()]
        [switch]
        $ScanOnly
        ,
        [Parameter()]
        [switch]
        $DownloadOnly
        ,
        [Parameter()]
        [ValidateSet('None', 'Shutdown', 'Reboot')]
        [string]
        $PowerAction = 'None'
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $PowerActionDelaySeconds = 5
    )

    $SearchString = @{
        'All'         = "IsInstalled=0 and Type='Software' and AutoSelectOnWebsites=1"
        'Recommended' = "IsInstalled=0 and Type='Software'"
    }
    Write-Information -Message ('[{0}] Using search string <{1}> based on filter <{2}>' -f $MyInvocation.MyCommand, $SearchString[$Filter], $Filter)
    
    Write-Information -Message ('[{0}] Searching for updates' -f $MyInvocation.MyCommand)
    $UpdateSession = New-Object -Com Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search($SearchString[$Filter])

    if ($SearchResult.Updates.Count -eq 0) {
        Write-Information -Message ('[{0}] No updates found' -f $MyInvocation.MyCommand)
        return
    }

    if ($ScanOnly) {
        Write-Information -Message ('[{0}] ScanOnly' -f $MyInvocation.MyCommand)
        foreach ($Update in $SearchResult.Updates) {
            Write-Host ('[{0}] Found update: {1}' -f $MyInvocation.MyCommand, $Update.Title)
        }
        Write-Information -Message ('[{0}] ScanOnly. Done.' -f $MyInvocation.MyCommand)
        return
    }

    Write-Information -Message ('[{0}] Building download list' -f $MyInvocation.MyCommand)
    $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
    foreach ($Update in $SearchResult.Updates) {
        Write-Information -Message ('[{0}] Adding an update to the download list: {0}.' -f $MyInvocation.MyCommand, $Update.Title)
        $UpdatesToDownload.Add($Update) | Out-Null
    }
    if ($UpdatesToDownload.Count -eq 0) {
        Write-Information -Message ('[{0}] No updates found. Aborting.' -f $MyInvocation.MyCommand)
        return
    }

    Write-Information -Message ('[{0}] Downloading updates' -f $MyInvocation.MyCommand)
    $Downloader = $UpdateSession.CreateUpdateDownloader()
    $Downloader.Updates = $UpdatesToDownload
    $Downloader.Download()

    if ($DownloadOnly) {
        Write-Information -Message ('[{0}] DownloadOnly. Done.' -f $MyInvocation.MyCommand)
        return
    }

    Write-Information -Message ('[{0}] Building installation list' -f $MyInvocation.MyCommand)
    $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
    foreach ($Update in $SearchResult.Updates) {
        if ($Update.IsDownloaded) {
            Write-Information -Message ('[{0}] Adding a downloaded update to the installation list: {0}.' -f $MyInvocation.MyCommand, $Update.Title)
            $UpdatesToInstall.Add($Update) | Out-Null
        }
    }
    if ($UpdatesToInstall.Count -eq 0) {
        Write-Information -Message ('[{0}] No updates downloaded. Aborting.' -f $MyInvocation.MyCommand)
        return
    }

    Write-Information -Message ('[{0}] Installing updates' -f $MyInvocation.MyCommand)
    $Installer = $UpdateSession.CreateUpdateInstaller()
    $Installer.Updates = $UpdatesToInstall
    $InstallationResult = $Installer.Install()

    if ($InstallationResult.RebootRequired -and $PowerAction -ine 'None') {
        Write-Information -Message ('[{0}] PowerAction' -f $MyInvocation.MyCommand)

        $PowerActionParameter = ''
        if ($PowerAction -ieq 'Shutdown') {
            $PowerActionParameter = '/s'

        } elseif ($PowerAction -ieq 'Reboot') {
            $PowerActionParameter = '/r'
        }
        Write-Information -Message ('[{0}] {1} ({2}) in {3} seconds' -f $MyInvocation.MyCommand, $PowerAction, $PowerActionParameter, $PowerActionDelaySeconds)
        shutdown.exe $PowerActionParameter /t $PowerActionDelaySeconds
    }

    Write-Information -Message ('[{0}] Done.' -f $MyInvocation.MyCommand)
}