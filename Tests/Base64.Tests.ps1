#$here = Split-Path -Parent $MyInvocation.MyCommand.Path
#$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

Import-Module "$PSScriptRoot\..\Support"

Describe 'Base64' {
    Context 'Conversion' {
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
    Context 'Unattended Password' {
        It 'Convert password to Base64 using parameter' {
            ConvertTo-UnattendXmlPassword -Password 'P@ssw0rd!' | Should Be (ConvertTo-Base64 -Data 'P@ssw0rd!')
        }
        It 'Convert password to Base64 using pipeline' {
            'P@ssw0rd!' | ConvertTo-UnattendXmlPassword | Should Be (ConvertTo-Base64 -Data 'P@ssw0rd!')
        }
        It 'Convert password from Base64 using parameter' {
            ConvertFrom-UnattendXmlPassword -Password (ConvertTo-Base64 -Data 'P@ssw0rd!') | Should Be 'P@ssw0rd!'
        }
        It 'Convert password from Base64 using pipeline' {
            ConvertTo-Base64 -Data 'P@ssw0rd!' | ConvertFrom-UnattendXmlPassword | Should Be 'P@ssw0rd!'
        }
    }
}