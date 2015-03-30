$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Base64' {
    It 'works for both piped' {
        $input = 'abcdefgh12345678'
        $input | ConvertTo-Base64 | ConvertFrom-Base64 | Should Be $input
    }
    It 'works for parameter and pipe (in that order)' {
        $input = 'abcdefgh12345678'
        ConvertTo-Base64 -Data $input | ConvertFrom-Base64 | Should Be $input
    }
    It 'works for pipe and parameter (in that order)' {
        $input = 'abcdefgh12345678'
        $data = $input | ConvertTo-Base64
        ConvertFrom-Base64 -Data $data | Should Be $input
    }
}