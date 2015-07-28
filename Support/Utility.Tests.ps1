$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Utility' {
    Context 'Get-CallerInvocationInfo' {
        It 'Returns the direct caller' {
            function Invoke-Something {
                Get-CallerInvocationInfo
            }
            (Invoke-Something).MyCommand.Name | Should Be 'Invoke-Something'
        }
        It 'Excludes logging functions' {
            function Write-Verbose {
                Get-CallerInvocationInfo -ExcludeLogging
            }
            function Invoke-Something {
                Write-Verbose
            }
            (Invoke-Something).MyCommand.Name | Should Be 'Invoke-Something'
        }
        It 'Returns second level caller' {
            function Invoke-InnerSomething {
                Get-CallerInvocationInfo -Index 2
            }
            function Invoke-OuterSomething {
                Invoke-InnerSomething
            }
            (Invoke-OuterSomething).MyCommand.Name | Should Be 'Invoke-OuterSomething'
        }
    }
    Context 'Get-InvocationName' {
        It 'Works for functions' {
            function Invoke-Something {
                Get-InvocationName -InvocationInfo $MyInvocation
            }
            Invoke-Something | Should Be 'Invoke-Something'
        }
        It 'Works for scripts' {
            @(
                ('. "{0}"' -f "$here/$sut")
                'Get-InvocationName -InvocationInfo $MyInvocation'
            ) | Set-Content -Path TestDrive:\Invoke-Something.ps1
            & TestDrive:\Invoke-Something.ps1 | Should Be 'Invoke-Something.ps1'
        }
        It 'Works for scriptblock' {
            Invoke-Command -ScriptBlock {
                Get-InvocationName -InvocationInfo $MyInvocation
            } | Should Be 'ScriptBlock'
        }
        It 'Works for dot sourcing' {
            @(
                ('. "{0}"' -f "$here/$sut")
                'Get-InvocationName'
            ) | Set-Content -Path TestDrive:\Invoke-Something.ps1
            $Path = Get-Item -Path TestDrive:\Invoke-Something.ps1 | Select-Object -ExpandProperty FullName
            ('. "{0}"' -f $Path) | Set-Content -Path TestDrive:\Caller.ps1
            & TestDrive:\Caller.ps1 | Should Be 'Invoke-Something.ps1'
        }
    }
    Context 'Get-ScriptPath' {
        It 'Returns the script path' {
            #
        }
    }
}