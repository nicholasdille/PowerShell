$here = ''
If ($MyInvocation.MyCommand.Path) {
    $here = Split-Path -Path $MyInvocation.MyCommand.Path
} Else {
    $here = $pwd -Replace '^\S+::',''
}

$tests = Get-ChildItem -Path (Join-Path -Path $here -ChildPath 'tests/*.tests.ps1')

$ConfirmPreference = 'None'

foreach ($file in $tests ) {
    $nunitxml = $file.FullName + '.nunit.result.xml'
    $clixml = $file.FullName + '.clixml.result.xml'
    Invoke-Pester -Path $($file.FullName) -OutputFormat NUnitXml -OutputFile $nunitxml -PassThru | Export-Clixml -Path $clixml
}

If ($env:APPVEYOR_JOB_ID) {
    ForEach ($file in (Get-ChildItem -Path (Join-Path -Path $here -ChildPath 'tests/*.nunit.result.xml'))) {
        $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
        $Source = $file.FullName

        "UPLOADING FILES: $Address $Source"

        (New-Object -TypeName System.Net.WebClient).UploadFile($Address, $Source)
    }

} Else {
    'Skipping Appveyor upload because this job is not running in Appveyor'
}

$Results = @( Get-ChildItem -Path (Join-Path -Path $here -ChildPath 'tests/*.clixml.result.xml') | Import-Clixml )

$FailedCount = $Results |
    Select -ExpandProperty FailedCount |
    Measure-Object -Sum |
    Select -ExpandProperty Sum

if ($FailedCount -gt 0) {
    $FailedItems = $Results |
        Select -ExpandProperty TestResult |
        Where {$_.Passed -notlike $True}

    "FAILED TESTS SUMMARY:`n"
    $FailedItems | ForEach-Object {
        $Test = $_
        [pscustomobject]@{
            Describe = $Test.Describe
            Context = $Test.Context
            Name = "It $($Test.Name)"
            Result = $Test.Result
        }
    } |
        Sort Describe, Context, Name, Result |
        Format-List

    throw "$FailedCount tests failed."
}