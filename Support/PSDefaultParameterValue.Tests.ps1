$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'PSDefaultParameterValues' {
    Context 'Backup-DefaultParameterValues' {
        It 'Backup' {
            Backup-DefaultParameterValues
            $Script:BackupOf_PSDefaultParameterValues | Should Be $PSDefaultParameterValues
        }
    }
    Context 'Restore-DefaultParameterValues' {
        It 'Restore' {
            Backup-DefaultParameterValues
            $PSDefaultParameterValues.'Invoke-Command:ComputerName' = 'localhost'
            Restore-DefaultParameterValues
            $Script:BackupOf_PSDefaultParameterValues | Should Be $PSDefaultParameterValues
        }
    }
    Context 'Set-DefaultParameterValue' {
        It 'Setting' {
            Backup-DefaultParameterValues
            Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
            $PSDefaultParameterValues.'Invoke-Command:ComputerName' | Should Be 'localhost'
            Restore-DefaultParameterValues
        }
    }
    Context 'Get-DefaultParameterValue' {
        It 'Getting' {
            Backup-DefaultParameterValues
            Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
            Get-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' | Should Be 'localhost'
            Restore-DefaultParameterValues
        }
    }
    Context 'Remove-DefaultParameterValue' {
        It 'Removing' {
            Backup-DefaultParameterValues
            Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
            Remove-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName'
            Get-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' | Should Be $null
            Restore-DefaultParameterValues
        }
    }
}