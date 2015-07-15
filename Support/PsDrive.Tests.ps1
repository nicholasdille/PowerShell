$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'PsDrive' {
    Context 'Find-DuplicateItem' {
        #
    }
    Context 'Move-DuplicateItem' {
        #
    }
    Context 'Get-FolderSize' {
        #
    }
    Context 'Get-Tree' {
        It 'Fails on missing path' {
            { Get-Tree -Path 'Testdrive:\missing' } | Should Throw
        }
        It 'Fails on file' {
            New-Item -Path Testdrive:\MyFile -ItemType File | Out-Null
            { Get-Tree -Path 'Testdrive:\MyFile' } | Should Throw
        }
        It 'Returns directories' {
            New-Item -Path Testdrive:\MyFolder -ItemType Directory | Out-Null
            New-Item -Path Testdrive:\MyFolder\MySubFolder -ItemType Directory | Out-Null
            $tree = Get-Tree -Path 'Testdrive:\MyFolder'
            $tree -is [array] | Should Be $true
            $tree.Count | Should Be 2
            $tree | Where-Object {$_ -like '*\MyFolder'} | Should Not BeNullOrEmpty
            $tree | Where-Object {$_ -like '*\MySubFolder'} | Should Not BeNullOrEmpty
        }
    }
    Context 'Get-FileExtension' {
        It 'Fails on missing path' {
            { Get-Tree -Path 'Testdrive:\missing' } | Should Throw
        }
        It 'Returns extensions and count' {
            New-Item -Path Testdrive:\file.txt -ItemType File | Out-Null
            New-Item -Path Testdrive:\file.ps1 -ItemType File | Out-Null
            New-Item -Path Testdrive:\file.cmd -ItemType File | Out-Null
            $data = Get-FileExtension -Path 'Testdrive:\'
            $data -is [array] | Should Be $true
            $data.Count | Should Be 3
            $data.Name -contains '.txt' | Should Be $true
            $data.Name -contains '.ps1' | Should Be $true
            $data.Name -contains '.cmd' | Should Be $true
            $data | Where-Object {$_.Name -eq '.txt'} | Select-Object -ExpandProperty Count | Should Be 1
            $data | Where-Object {$_.Name -eq '.ps1'} | Select-Object -ExpandProperty Count | Should Be 1
            $data | Where-Object {$_.Name -eq '.cmd'} | Select-Object -ExpandProperty Count | Should Be 1
        }

    }
    Context 'Get-DuplicateItem' {
        #
    }
}