$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'CSV' {
    Context 'Import-Array' {
        It 'Imports lines into array' {
            @(
                'line1'
                'line2'
            ) | Set-Content -Path Testdrive:\input.txt
            $data = Import-Array -File Testdrive:\input.txt
            $data -is [array] | Should Be $true
            $data -contains 'line1' | Should Be $true
            $data -contains 'line2' | Should Be $true
        }
        It 'Chooses the correct file' {
            @(
                'line1'
                'line2'
            ) | Set-Content -Path Testdrive:\input.txt
            @(
                'line3'
                'line4'
            ) | Set-Content -Path Testdrive:\input-override.txt
            $data = Import-Array -File Testdrive:\input-override.txt,Testdrive:\input.txt
            $data -contains 'line3' | Should Be $true
        }
    }
}