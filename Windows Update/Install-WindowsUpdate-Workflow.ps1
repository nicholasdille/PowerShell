workflow Install-WindowsUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet('All', 'Recommended')]
        [string]
        $Filter = 'Recommended'
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        $ScanOnly
        ,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Shutdown', 'Reboot')]
        [string]
        $PowerAction = 'Reboot'
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PowerActionDelaySeconds = 5
    )

    InlineScript {
        $Filter                  = $Using:Filter
        $ScanOnly                = $Using:ScanOnly
        $PowerAction             = $Using:PowerAction
        $PowerActionDelaySeconds = $Using:PowerActionDelaySeconds


        $SearchString = @{
            'All'         = "IsInstalled=0 and Type='Software' and AutoSelectOnWebsites=1"
            'Recommended' = "IsInstalled=0 and Type='Software'"
        }
    
        $UpdateSession = New-Object -Com Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        Write-Verbose ('Using filter <{0}> for search' -f $Filter)
        $SearchResult = $UpdateSearcher.Search($SearchString[$Filter])

        if ($SearchResult.Updates.Count -eq 0) {
            Write-Verbose 'No updates found'
            return
        }

        if ($ScanOnly) {
            foreach ($Update in $SearchResult.Updates) {
                Write-Verbose $Update.Title
            }
            return
        }

        $UpdatesToDownload = New-Object -Com Microsoft.Update.UpdateColl
        foreach ($Update in $SearchResult.Updates) {
            Write-Verbose ('Adding an update to the download list: {0}.' -f $Update.Title)
            $UpdatesToDownload.Add($Update) | Out-Null
        }
        if ($UpdatesToDownload.Count -eq 0) {
            Write-Verbose 'No updates found. Aborting.'
            return
        }

        #$Downloader = $UpdateSession.CreateUpdateDownloader()
        $Downloader = New-Object -Com Microsoft.Update.Downloader
        $Downloader.Updates = $UpdatesToDownload
        Write-Verbose 'Downloading updates ...'
        $Downloader.Download()

        $UpdatesToInstall = New-Object -Com Microsoft.Update.UpdateColl
        foreach ($Update in $SearchResult.Updates) {
            if ($Update.IsDownloaded) {
                Write-Verbose ('Adding a downloaded update to the installation list: {0}.' -f $Update.Title)
                $UpdatesToInstall.Add($Update) | Out-Null
            }
        }
        if ($UpdatesToInstall.Count -eq 0) {
            Write-Verbose 'No updates downloaded. Aborting.'
            return
        }

        $Installer = $UpdateSession.CreateUpdateInstaller()
        Write-Verbose 'Installing Updates ...'
        $Installer.Updates = $UpdatesToInstall
        $InstallationResult = $Installer.Install()
        Write-Verbose 'Installation completed'

        if ($InstallationResult.RebootRequired) {
            $PowerActionParameter = ''
            if ($PowerAction -ieq 'Shutdown') {
                $PowerActionParameter = '/s'

            } elseif ($PowerAction -ieq 'Reboot') {
                $PowerActionParameter = '/r'
            }
            Write-Verbose ('{0} ({1}) in {2} seconds' -f $PowerAction, $PowerActionParameter, $PowerActionDelaySeconds)
            shutdown.exe $PowerActionParameter /t $PowerActionDelaySeconds
        }
    }
}