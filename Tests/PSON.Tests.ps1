$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

#Import-Module "$PSScriptRoot\..\Support"
. "$PSScriptRoot\..\Support\$sut"

Describe 'PowerShell Object Notation' {
    Context 'ConvertFrom-Pson' {
        It 'Throws on missing file' {
            { ConvertFrom-Pson -Path TestDrive:\MissingFile.txt } | Should Throw
        }
        It 'Imports PSON' {
            @(
                '@{'
                '    AllNodes = @('
                '        @{'
                '            NodeName = "*"'
                '            PsDscAllowPlaintextPassword = $true'
                '        }'
                '        @{'
                '            NodeName = "DC-01"'
                '            Role = "DomainController"'
                '        }'
                '    )'
                '}'
            ) | Set-Content -Path TestDrive:\pson.psd1
            $pson = ConvertFrom-Pson -Path TestDrive:\pson.psd1
            $pson.AllNodes[0].NodeName | Should Be '*'
            $pson.AllNodes[1].Role | Should Be 'DomainController'
        }
    }
}