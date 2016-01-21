#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

Import-Module "$PSScriptRoot\..\Support"

Describe 'Jobs' {
    Context 'Invoke-Queue' {
        It 'Returns a single object for a single input object' {
            $Jobs = Invoke-Queue -InputObject @(1) -Scriptblock {} -Delay 0
            $Jobs -is [array] | Should Be $false
            $Jobs[0] -is [System.Management.Automation.Job] | Should Be $true
        }
        It 'Returns an array with more than one input object' {
            (Invoke-Queue -InputObject @(1, 2) -Scriptblock {} -Delay 0) -is [array] | Should Be $true
        }
        It 'Calls the scriptblock' {
            $OuterVariable = $true
            $Jobs = Invoke-Queue -InputObject @(1, 2) -Scriptblock {$Using:OuterVariable} -Delay 0 | Wait-Job
            $ReturnValue = $Jobs[0] | Receive-Job
            $ReturnValue | Should Be $OuterVariable
        }
        It 'Successfully completes jobs on successful code' {
            $j = Invoke-Queue -InputObject @(1, 2) -Scriptblock {Write-Output 'Hello, World!'} -Delay 0 | Wait-Job
            $j | Where-Object {$_.State -ieq 'Completed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
        }
        It 'Fails jobs on failed code' {
            $j = Invoke-Queue -InputObject @(1, 2) -Scriptblock {throw} -Delay 0 | Wait-Job
            $j | Where-Object {$_.State -ieq 'Failed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
        }
        It 'Throttle execution' {
            $Jobs = Invoke-Queue -InputObject @(1, 2) -Scriptblock {Start-Sleep -Seconds 1} -ThrottleLimit 1 -Delay 0
            $States = $Jobs | Select-Object -ExpandProperty State | Group-Object
            $States | Where-Object {$_.Name -ieq 'Completed'} | Select-Object -ExpandProperty Count | Should Be 1
            $States | Where-Object {$_.Name -ieq 'Running'} | Select-Object -ExpandProperty Count | Should Be 1
        }
    }
    Context 'ConvertTo-Progress' {
        It 'Works with a parameter' {
            Mock Write-Progress {}
            $output = ConvertTo-Progress -ProgressText 'blarg'
            Assert-MockCalled Write-Progress -Exactly -Times 0
            $output | Should Be 'blarg'
        }
        It 'Works on the pipeline' {
            Mock Write-Progress {}
            $output = 'blarg' | ConvertTo-Progress
            Assert-MockCalled Write-Progress -Exactly -Times 0
            $output | Should Be 'blarg'
        }
        It 'Writes progress on proper input' {
            Mock Write-Progress {}
            'Activity="Activity Text" Status="Status Text" Percentage=10' | ConvertTo-Progress | Out-Null
            Assert-MockCalled Write-Progress -Times 1
        }
        It 'Correctly separates progress and output' {
            Mock Write-Progress {}
            $output = 'blarg','Activity="Activity Text" Status="Status Text" Percentage=10' | ConvertTo-Progress
            Assert-MockCalled Write-Progress -Times 1
            $output | Should Be 'blarg'
        }
        It 'Outputs the expected progress' {
            Mock Write-Progress {} -ParameterFilter {$Activity -ieq 'Activity Text' -and $Status -ieq 'Status Text' -and $PercentageComplete -eq 10}
            'Activity="Activity Text" Status="Status Text" Percentage=10' | ConvertTo-Progress | Out-Null
            Assert-MockCalled Write-Progress -Times 1
        }
        It 'Correctly fills all progress fields' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 1 -and $ParentId -eq 1248 -and $Activity -ieq 'Activity Text' -and $Status -ieq 'Status Text' -and $Operation -ieq 'Operation Text' -and $PercentageComplete -eq 10}
            'Id=1 ParentId=1248 Activity="Activity Text" Status="Status Text" Operation="Operation Text" Percentage=10' | ConvertTo-Progress | Out-Null
            Assert-MockCalled Write-Progress -Times 1
        }
        It 'Presets job and parent ID' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 1 -and $ParentId -eq 1248}
            'Activity="Activity Text" Status="Status Text" Percentage=10' | ConvertTo-Progress | Out-Null
            Assert-MockCalled Write-Progress -Times 1
        }
        It 'Preset IDs are overridden' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 1 -and $ParentId -eq 1248}
            'Activity="Id=2 ParentId=1249 Activity Text" Status="Status Text" Percentage=10' | ConvertTo-Progress | Out-Null
            Assert-MockCalled Write-Progress -Times 1
        }
    }
    Context 'Show-JobProgress' {
        It 'Captures job progress' {
            Mock Write-Progress {}
            $Job = Start-Job -ScriptBlock {Write-Progress -Activity 'Activity Text' -Status 'Status Text' -PercentComplete 10} | Wait-Job
            $Job | Show-JobProgress
            Assert-MockCalled Write-Progress -Exactly -Times 1
        }
        It 'Fills the progress fields correctly' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 0 -and $ParentId -eq 1248 -and $Activity -ieq 'Activity Text' -and $Status -ieq 'Status Text' -and $Operation -ieq 'Operation Text' -and $PercentageComplete -eq 10}
            $Job = Start-Job -ScriptBlock {Write-Progress -Id 0 -ParentId 1248 -Activity 'Activity Text' -Status 'Status Text' -Operation 'Operation Text' -PercentComplete 10} | Wait-Job
            $Job | Show-JobProgress
            Assert-MockCalled Write-Progress -Exactly -Times 1
        }
        It 'Displays multiple progress message for different IDs' {
            Mock Write-Progress {}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Id 0 -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
                Write-Progress -Id 1 -Activity 'Activity Text 2' -Status 'Status Text' -PercentComplete 11
            } | Wait-Job
            $Job | Show-JobProgress
            Assert-MockCalled Write-Progress -Exactly -Times 3
        }
        It 'Displays only the filtered progress messages' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 10}
            Mock Write-Progress {} -ParameterFilter {$Id -eq 11}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Id 10 -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
                Write-Progress -Id 11 -Activity 'Activity Text 2' -Status 'Status Text' -PercentComplete 11
            } | Wait-Job
            $Job | Show-JobProgress -FilterScript {$Activity -like '*2'}
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$Id -eq 11}
            Assert-MockCalled Write-Progress -Exactly -Times 0 -ParameterFilter {$Id -eq 10}
        }
        It 'Adds parent ID to progress messages' {
            Mock Write-Progress {} -ParameterFilter {$ParentId -eq 1248}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
            } | Wait-Job
            $Job | Show-JobProgress -ParentId 1248
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$ParentId -eq 1248}
        }
        It 'Automatically sets unique IDs on progress messages' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 0}
            Mock Write-Progress {} -ParameterFilter {$Id -eq 1}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
                Write-Progress -Activity 'Activity Text 2' -Status 'Status Text' -PercentComplete 11
            } | Wait-Job
            $Job | Show-JobProgress -GenerateUniqueId
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$Id -eq 0}
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$Id -eq 1}
        }
        It 'Autogenerated unique IDs with specified offset' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 16}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
            } | Wait-Job
            $Job | Show-JobProgress -GenerateUniqueId -UniqueIdOffset 15
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$Id -eq 16}
        }
        It 'Autogenerated unique IDs with offset based on parent ID' {
            Mock Write-Progress {} -ParameterFilter {$Id -eq 21}
            $Job = Start-Job -ScriptBlock {
                Write-Progress -Activity 'Activity Text 1' -Status 'Status Text' -PercentComplete 10
            } | Wait-Job
            $Job | Show-JobProgress -GenerateUniqueId -ParentId 20
            Assert-MockCalled Write-Progress -Exactly -Times 1 -ParameterFilter {$Id -eq 21}
        }
    }
}