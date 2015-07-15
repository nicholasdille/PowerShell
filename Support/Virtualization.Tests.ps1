$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Virtualization' {
    Context 'Get-VmIdFromHyperV' {
        It 'Calls Get-VM from HyperV module' {
            Mock Get-VM {}
            Get-VmIdFromHyperV -ComputerName 'somehost' -Name 'somevm' | Should Not BeNullOrEmpty
            Assert-MockCalled Get-VM -Exactly -Times 1
        }
    }
    Context 'Get-VmIdFromVmm' {
        It 'Calls Get-SCVirtualMachine from VMM module' {
            Mock Get-SCVirtualMachine {}
            Get-VmIdFromVmm -ComputerName 'somehost' -Name 'somevm' | Should Not BeNullOrEmpty
            Assert-MockCalled Get-SCVirtualMachine -Exactly -Times 1
        }
    }
    Context 'Get-VmIp' {
    }
}