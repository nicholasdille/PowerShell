$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Hash Tables' {
    Context 'New-HashFromArrays' {
        It 'Returns a hash' {
            $hash = New-HashFromArrays -Keys ('a','b','c') -Values (1,2,3)
            $hash -is [hashtable] | Should Be $true
        }
        It 'Returns a hash of correct size' {
            $hash = New-HashFromArrays -Keys ('a','b','c') -Values (1,2,3)
            $hash.Count | Should Be 3
        }
        It 'Returns a hash with correct keys and values' {
            $hash = New-HashFromArrays -Keys ('a','b','c') -Values (1,2,3)
            $hash.Keys -contains 'a' | Should Be $true
            $hash.Keys -contains 'b' | Should Be $true
            $hash.Keys -contains 'c' | Should Be $true
            $hash.Values -contains 1 | Should Be $true
            $hash.Values -contains 2 | Should Be $true
            $hash.Values -contains 3 | Should Be $true
        }
    }
    Context 'ConvertTo-Hash' {
        It 'Returns a hash' {
            $hash = ConvertTo-Hash -Array @('a','b','c') -Value 0
            $hash -is [hashtable] | Should Be $true
        }
        It 'Returns a hash of correct size' {
            $hash = ConvertTo-Hash -Array @('a','b','c') -Value 0
            $hash.Count | Should Be 3
        }
        It 'Returns a hash with correct keys and values' {
            $hash = ConvertTo-Hash -Array @('a','b','c') -Value 0
            $hash.Keys -contains 'a' | Should Be $true
            $hash.Keys -contains 'b' | Should Be $true
            $hash.Keys -contains 'c' | Should Be $true
            $hash.Values | Where-Object {$_ -eq 0} | Measure-Object -Line | Select-Object -ExpandProperty Lines | Should Be 3
        }
    }
}