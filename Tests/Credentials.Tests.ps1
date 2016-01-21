$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

#Import-Module "$PSScriptRoot\..\Support"
. "$PSScriptRoot\..\Support\$sut"

Describe 'Credential Store' {
    Context 'New-CredentialInStore' {
        It 'Check creation of new credential' {
            New-Item -Path 'TestDrive:\Cred' -ItemType Directory | Out-Null
            $Password   = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('domain\user', $Password)
            New-CredentialInStore -CredentialName 'user@domain' -Credential $Credential -CredentialStore 'TestDrive:\Cred'
            'TestDrive:\Cred\user@domain.clixml' | Should Exist
        }
    }
    Context 'Get-CredentialFromStore' {
        It 'Retrieve credential from store' {
            New-Item -Path 'TestDrive:\Cred' -ItemType Directory
            $Password   = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('domain\user', $Password)
            New-CredentialInStore -CredentialName 'user@domain' -Credential $Credential -CredentialStore 'TestDrive:\Cred'
            $Credential2 = Get-CredentialFromStore -CredentialName 'user@domain' -CredentialStore 'TestDrive:\Cred'
            $Credential2.UserName -ieq 'domain\user' | Should Be $true
            $Credential2.GetNetworkCredential().Password -ieq 'P@ssw0rd!' | Should Be $true
        }
    }
    Context 'New-PsRemoteSession' {
        It 'Creates a new remote session' {
            Mock New-PSSession {return $null}
            { New-PsRemoteSession -ComputerName someserver } | Should Throw
            Assert-MockCalled New-PSSession -Exactly -Times 1
        }
    }
    Context 'Enter-PsRemoteSession' {
        It 'Enters a remote session' {
            Mock Enter-PSSession {}
            Enter-PsRemoteSession -ComputerName localhost
            Assert-MockCalled Enter-PSSession -Exactly -Times 1
        }
    }
    Context 'New-SimpleCimSession' {
        It 'Creates a new remote session' {
            Mock New-CimSession {return $null}
            { New-SimpleCimSession -ComputerName someserver } | Should Throw
            Assert-MockCalled New-CimSession -Exactly -Times 1
        }
    }
    Context 'Test-Credential' {}
}