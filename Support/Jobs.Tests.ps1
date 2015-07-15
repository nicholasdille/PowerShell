﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Process-Queue' {
    It 'Returns a single object without a single input object' {
        (Process-Queue -InputObject @(1) -Scriptblock {}) -isnot [array] | Should Be $true
    }
    It 'Returns an array with more than one input object' {
        (Process-Queue -InputObject @(1, 2) -Scriptblock {}) -is [array] | Should Be $true
    }
    #It 'Calls the scriptblock' {
    #    function Invoke-MyCode {}
    #    $sb = (Get-Item -Path Function:\Invoke-MyCode).ScriptBlock
    #    Mock Invoke-MyCode {}
    #    Process-Queue -InputObject @(1, 2) -Scriptblock $sb | Wait-Job | Out-Null
    #    Assert-MockCalled Invoke-MyCode -Exactly -Times 2 -Scope It
    #}
    It 'Successfully completes jobs on successful code' {
        $j = Process-Queue -InputObject @(1, 2) -Scriptblock {} | Wait-Job
        $j | Where-Object {$_.State -ieq 'Completed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
    }
    It 'Fails jobs on failed code' {
        $j = Process-Queue -InputObject @(1, 2) -Scriptblock {throw} | Wait-Job
        $j | Where-Object {$_.State -ieq 'Failed'} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 2
    }
    #It 'Throttle execution' {
    #    Mock Start-Sleep {} -ParameterFilter {$Delay -eq 2}
    #    Process-Queue -InputObject @(1, 2) -Scriptblock {} -ThrottleLimit 1 | Out-Null
    #    Assert-MockCalled Start-Sleep -Exactly -Times 1 -Scope It
    #}
}