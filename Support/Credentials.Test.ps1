$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

Describe 'Credential Store' {
    Context 'New-CredentialInStore' {
        It 'Check creation of new credential' {
            New-Item -Path 'TestDrive:\Cred' -ItemType File | Out-Null
            $Password   = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('domain\user', $Password)
            New-CredentialInStore -CredentialName 'user@domain' -Credential $Credential -CredentialStore 'TestDrive:\Cred'
            'TestDrive:\Cred\user@domain.clixml' | Should Exist
        }
    }
    Context 'Get-CredentialFromStore' {
        It 'Retrieve credential from store' {
            New-Item -Path 'TestDrive:\Cred' -ItemType File
            $Password   = ConvertTo-SecureString 'P@ssw0rd!' -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ('domain\user', $Password)
            New-CredentialInStore -CredentialName 'user@domain' -Credential $Credential -CredentialStore 'TestDrive:\Cred'
            $Credential2 = Get-CredentialFromStore -CredentialName 'user@domain' -CredentialStore 'TestDrive:\Cred'
            $Credential2.UserName -ieq 'domain\user' | Should Be $true
            $Credential2.GetNetworkCredential().Password -ieq 'P@ssw0rd!' | Should Be $true
        }
    }
    Context 'New-PsRemoteSession' {
    }
    Context 'Enter-PsRemoteSession' {
    }
    Context 'New-SimpleCimSession' {
    }
}