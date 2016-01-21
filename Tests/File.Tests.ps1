#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

Import-Module "$PSScriptRoot\..\Support"

Describe 'BinaryFile/FileHash' {
    Context 'New-File' {
        $Path = Get-Item -Path TestDrive:\ | Select-Object -ExpandProperty FullName
        $file = New-File -BasePath $Path -FileCount 1 -ChunkCount 10 -ChunkSize (100KB)

        It 'Creates a file with correct size' {
            @($file).Count | Should Be 1
            Get-Item -Path $file | Select-Object -ExpandProperty Length | Should Be (1000KB)
        }
    }
    Context 'Split-BinaryFile' {
        $Path = Get-Item -Path TestDrive:\ | Select-Object -ExpandProperty FullName
        $file = New-File -BasePath $Path -FileCount 1 -ChunkCount 10 -ChunkSize (100KB)
            
        It 'Creates the correct number of chunks' {
            (Split-BinaryFile -Path $file -Size 100KB).Count | Should Be 10
        }
    }
}