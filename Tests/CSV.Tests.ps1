#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

Import-Module "$PSScriptRoot\..\Support"

Describe 'CSV' {
    Context 'Import-Array' {
        It 'Fails for missing file' {
            { Import-Array -File Testdrive:\missing.txt } | Should Throw
        }
        It 'Imports lines into array' {
            @('line1', 'line2') | Set-Content -Path Testdrive:\input.txt
            'Testdrive:\input.txt' | Should Exist
            $data = Import-Array -File Testdrive:\input.txt
            $data -is [array] | Should Be $true
            $data -contains 'line1' | Should Be $true
            $data -contains 'line2' | Should Be $true
        }
        It 'Chooses the correct file' {
            @('line1', 'line2') | Set-Content -Path Testdrive:\input.txt
            'Testdrive:\input.txt' | Should Exist
            @('line3', 'line4') | Set-Content -Path Testdrive:\input-override.txt
            'Testdrive:\input-override.txt' | Should Exist
            $data = Import-Array -File Testdrive:\input-override.txt,Testdrive:\input.txt
            $data -contains 'line3' | Should Be $true
        }
    }
    Context 'Import-Hash' {
        It 'Fails for missing file' {
            { Import-Hash -File Testdrive:\missing.txt } | Should Throw
        }
        It 'Imports lines into hash' {
            @('key1;value1', 'key2;value2') | Set-Content -Path Testdrive:\input.txt
            'Testdrive:\input.txt' | Should Exist
            $data = Import-Hash -File Testdrive:\input.txt -Header 'key','value'
            $data -is [array] | Should Be $true
            $data.Count | Should Be 2
            $data | Where-Object {$_.key -ieq 'key1'} | Select-Object -ExpandProperty value | Should Be 'value1'
            $data | Where-Object {$_.key -ieq 'key2'} | Select-Object -ExpandProperty value | Should Be 'value2'
        }
        It 'Chooses the correct file' {
            @('key1;value1', 'key2;value2') | Set-Content -Path Testdrive:\input.txt
            'Testdrive:\input.txt' | Should Exist
            @('key3;value3', 'key4;value4') | Set-Content -Path Testdrive:\input-override.txt
            'Testdrive:\input-override.txt' | Should Exist
            $data = Import-Hash -File Testdrive:\input-override.txt,Testdrive:\input.txt -Header 'key','value'
            $data -is [array] | Should Be $true
            $data.Count | Should Be 2
            $data | Where-Object {$_.key -ieq 'key3'} | Select-Object -ExpandProperty value | Should Be 'value3'
        }
    }
}