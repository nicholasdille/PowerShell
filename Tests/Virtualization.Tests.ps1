#Requires -Modules Hyper-V, VirtualMachineManager

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

#Import-Module "$PSScriptRoot\..\Support"
. "$PSScriptRoot\..\Support\$sut"

Describe 'Virtualization' {
    Context 'Get-VmIdFromHyperV' {
        It 'Calls Get-VM from HyperV module' {
            Mock Get-VM {
                [pscustomobject]@{Id = 1234}
            }
            Get-VmIdFromHyperV -ComputerName 'somehost' -Name 'somevm' | Should Be 1234
            Assert-MockCalled Get-VM -Exactly -Times 1
        }
    }
    Context 'Get-VmIdFromVmm' {
        It 'Calls Get-SCVirtualMachine from VMM module' {
            Mock Get-SCVirtualMachine {
                [pscustomobject]@{Id = 2345}
            }
            Get-VmIdFromVmm -VMMServer 'somehost' -Name 'somevm' | Should Be 2345
            Assert-MockCalled Get-SCVirtualMachine -Exactly -Times 1
        }
    }
    Context 'Get-VmIp' {
    }
}