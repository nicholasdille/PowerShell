$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Jobs' {
    Context 'Invoke-Queue' {
        It 'Returns a single object for a single input object' {
            $Jobs = Invoke-Queue -InputObject @(1) -Scriptblock {}
            $Jobs -is [array] | Should Be $false
        }
        It 'Returns an array with more than one input object' {
            (Invoke-Queue -InputObject @(1, 2) -Scriptblock {}) -is [array] | Should Be $true
        }
        It 'Calls the scriptblock' {
            function Invoke-MyCode {}
            Invoke-Queue -InputObject @(1, 2) -Scriptblock {Invoke-MyCode} | Wait-Job | Out-Null
        }
        It 'Successfully completes jobs on successful code' {
            $j = Invoke-Queue -InputObject @(1, 2) -Scriptblock {Start-Sleep -Seconds 1} | Wait-Job
            $j | Where-Object {$_.State -ieq 'Completed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
        }
        It 'Fails jobs on failed code' {
            $j = Invoke-Queue -InputObject @(1, 2) -Scriptblock {throw} | Wait-Job
            $j | Where-Object {$_.State -ieq 'Failed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
        }
        #It 'Throttle execution' {
        #    Mock Start-Sleep {} -ParameterFilter {$Delay -eq 2}
        #    Invoke-Queue -InputObject @(1, 2) -Scriptblock {} -ThrottleLimit 1 | Out-Null
        #    Assert-MockCalled Start-Sleep -Exactly -Times 1 -Scope It
        #}
    }
}