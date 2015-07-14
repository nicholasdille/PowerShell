$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'BinaryFile/FileHash' {

    $TempPath = [System.IO.Path]::GetTempPath()
    $FileName = [System.IO.Path]::GetRandomFileName()
    $TempFilePath = "$TempPath$FileName"
    fsutil.exe file createnew $TempFilePath (1000KB)

    It 'Split binary file' {
        (Split-BinaryFile -Path $TempFilePath -Size 100KB).Count | Should Be 10
    }

    Get-ChildItem -Path $TempPath -File -Filter "$FileName.*" | Remove-Item -WhatIf
}