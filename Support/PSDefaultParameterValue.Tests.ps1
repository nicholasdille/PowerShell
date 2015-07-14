$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'PSDefaultParameterValues' {
    It 'Backup' {
        Backup-DefaultParameterValues
        $Script:BackupOf_PSDefaultParameterValues | Should Be $PSDefaultParameterValues
    }
    It 'Restore' {
        Backup-DefaultParameterValues
        $PSDefaultParameterValues.'Invoke-Command:ComputerName' = 'localhost'
        Restore-DefaultParameterValues
        $Script:BackupOf_PSDefaultParameterValues | Should Be $PSDefaultParameterValues
    }
    It 'Setting' {
        Backup-DefaultParameterValues
        Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
        $PSDefaultParameterValues.'Invoke-Command:ComputerName' | Should Be 'localhost'
        Restore-DefaultParameterValues
    }
    It 'Getting' {
        Backup-DefaultParameterValues
        Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
        Get-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' | Should Be 'localhost'
        Restore-DefaultParameterValues
    }
    It 'Removing' {
        Backup-DefaultParameterValues
        Set-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' -ParameterValue 'localhost'
        Remove-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName'
        Get-DefaultParameterValue -CmdletName 'Invoke-Command' -ParameterName 'ComputerName' | Should Be $null
        Restore-DefaultParameterValues
    }
}