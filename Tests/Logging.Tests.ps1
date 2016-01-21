#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

Import-Module "$PSScriptRoot\..\Support"

Describe 'Logging' {
    $LoggingLevel = 'Information'
    $LoggingFilePath = "TestDrive:\$(Split-Path -Path $LoggingFilePath -Leaf)"

    It 'Creates log file on first Write-Log' {
        Write-Log -Message 'Test'
        Test-Path -Path $LoggingFilePath | Should Be $true
    }
    It 'Does not log on LoggingPreference=SilentlyContinue' {
        Mock Out-File {}
        $LoggingPreference = 'SilentlyContinue'
        Write-Log -Message 'Test'
        Assert-MockCalled Out-File -Exactly -Times 0
    }
    It 'Logs on LoggingPreference=Continue' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Log -Message 'Test'
        Assert-MockCalled Out-File -Exactly -Times 1
    }
    It 'Logs for Write-Host' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Host 'Ignore this message'
        Assert-MockCalled Out-File -Exactly -Times 2
    }
    It 'Logs for Write-Output' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Output 'Test'
        Assert-MockCalled Out-File -Exactly -Times 3
    }
    It 'Logs for Write-Warning' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Warning 'Ignore this message'
        Assert-MockCalled Out-File -Exactly -Times 4
    }
    It 'Logs for Write-Error' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Error 'Ignore this message'
        Assert-MockCalled Out-File -Exactly -Times 5
    }
    It 'Logs for Write-Verbose' {
        Mock Out-File {}
        $LoggingPreference = 'Continue'
        Write-Verbose 'Test'
        Assert-MockCalled Out-File -Exactly -Times 6
    }
}