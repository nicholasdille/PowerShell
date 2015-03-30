$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Get-PlaintextFromSecureString' {
    It 'shows plaintext from piped SecureString' {
        ConvertTo-SecureString -String 'test' -AsPlainText -Force | Get-PlaintextFromSecureString | Should Be 'test'
    }
    It 'shows plaintext from SecureString parameter' {
        $input = ConvertTo-SecureString -String 'test' -AsPlainText -Force
        Get-PlaintextFromSecureString -SecureString $input | Should Be 'test'
    }
}

Describe 'EncryptedString' {
    It 'works for both piped' {
        $input = ConvertTo-SecureString -String 'test' -AsPlainText -Force
        $input | ConvertTo-EncryptedString -Key '0123456789abcedf' | ConvertFrom-EncryptedString -Key '0123456789abcedf' | Get-PlaintextFromSecureString | Should Be (Get-PlaintextFromSecureString -SecureString $input)
    }
    It 'works for parameter and pipe (in that order)' {
        $input = ConvertTo-SecureString -String 'test' -AsPlainText -Force
        ConvertTo-EncryptedString -SecureString $input -Key '0123456789abcedf' | ConvertFrom-EncryptedString -Key '0123456789abcedf' | Get-PlaintextFromSecureString | Should Be (Get-PlaintextFromSecureString -SecureString $input)
    }
    It 'works for pipe and parameter (in that order)' {
        $input = ConvertTo-SecureString -String 'test' -AsPlainText -Force
        $encrypted = $input | ConvertTo-EncryptedString -Key '0123456789abcedf'
        ConvertFrom-EncryptedString -EncryptedString $encrypted -Key '0123456789abcedf' | Get-PlaintextFromSecureString | Should Be (Get-PlaintextFromSecureString -SecureString $input)
    }
}