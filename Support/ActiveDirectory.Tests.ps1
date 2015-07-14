$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

#Requires -Modules ActiveDirectory

Describe 'Active Directory' {
    Context 'Get-DomainController' {
        It 'Finds domain controller' {
            Mock Resolve-DnsName {
                @(
                    [pscustomobject]@{Name = 'dc-01.mydomain.local'; Type = 'A'}
                    [pscustomobject]@{Name = 'dc-02.mydomain.local'; Type = 'A'}
                )
            }
            Mock Get-ADComputer {
                [pscustomobject]@{DNSHostName = 'dc-01.mydomain.local'}
            }

            $DomainController = Get-DomainController -DomainName 'mydomain.local'
            $DomainController -is [string] | Should Be $true
            $DomainController | Should Be 'dc-01.mydomain.local'
        }
        It 'Throws on unknown domain' {
            Mock Resolve-DnsName {}

            {Get-DomainController -DomainName 'mydomain.local'} | Should Throw
        }
        It 'Fails on invalid credentials' {
            Mock Resolve-DnsName {
                @(
                    [pscustomobject]@{Name = 'dc-01.mydomain.local'; Type = 'A'}
                    [pscustomobject]@{Name = 'dc-02.mydomain.local'; Type = 'A'}
                )
            }
            Mock Get-ADComputer { throw [System.Security.Authentication.AuthenticationException]::new() }
            Mock Write-Warning {}

            {Get-DomainController -DomainName 'mydomain.local'} | Should Throw
        }
        It 'Fails on server unreachable' {
            Mock Resolve-DnsName {
                @(
                    [pscustomobject]@{Name = 'dc-01.mydomain.local'; Type = 'A'}
                    [pscustomobject]@{Name = 'dc-02.mydomain.local'; Type = 'A'}
                )
            }
            Mock Get-ADComputer { throw [Microsoft.ActiveDirectory.Management.ADServerDownException]::new() }
            Mock Write-Warning {}

            {Get-DomainController -DomainName 'mydomain.local'} | Should Throw
        }
        It 'Fails on server not found' {
            Mock Resolve-DnsName {
                @(
                    [pscustomobject]@{Name = 'dc-01.mydomain.local'; Type = 'A'}
                    [pscustomobject]@{Name = 'dc-02.mydomain.local'; Type = 'A'}
                )
            }
            Mock Get-ADComputer { throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new() }

            {Get-DomainController -DomainName 'mydomain.local'} | Should Throw
        }
    }
    Context 'Test-Group' {
        It 'Fails on server not found' {
            Mock Get-ADGroup { throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new() }

            Test-Group -Identity 'MyGroup' | Should Be $false
        }
        It 'Tests for existing group' {
            Mock Get-ADGroup { $true }

            Test-Group -Identity 'MyGroup' | Should Be $true
        }
        It 'Tests for missing group' {
            Mock Get-ADGroup { throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new() }

            Test-Group -Identity 'MyGroup' | Should Be $false
        }
    }
    Context 'New-Group' {
        It 'Completes for existing group' {
            Mock Test-Group { $true }
            New-Group -Identity 'MyGroup' -Category Security -Scope Global -Path 'CN=Users,DC=mydomain,DC=local' | Should Be $true
        }
        It 'Completes for new group' {
            Mock Test-Group { $false }
            Mock New-ADGroup {}
            New-Group -Identity 'MyGroup' -Category Security -Scope Global -Path 'CN=Users,DC=mydomain,DC=local' #| Should Be $true
            Assert-MockCalled New-ADGroup -Times 1
        }
        It 'Fails with AD operation' {
            Mock Test-Group { $false }
            Mock New-ADGroup { throw }
            Mock Write-Error {}
            New-Group -Identity 'MyGroup' -Category Security -Scope Global -Path 'CN=Users,DC=mydomain,DC=local' | Should Be $false
        }
    }
    Context 'New-Member' {
        It 'Fails on missing group' {
            Mock Test-Group { $false }
            Mock Write-Error {}
            New-Member -Identity 'ADObject' -MemberOf 'MyGroup' | Should Be $false
        }
        It 'Completes' {
            Mock Test-Group { $true }
            Mock Add-ADPrincipalGroupMembership {}
            New-Member -Identity 'ADObject' -MemberOf 'MyGroup' | Should Be $true
        }
        It 'Fails' {
            Mock Test-Group { $true }
            Mock Add-ADPrincipalGroupMembership { throw }
            New-Member -Identity 'ADObject' -MemberOf 'MyGroup' | Should Be $false
        }
    }
    Context 'Rename-ADGroup' {
        It 'Fails on missing group' {
            Mock Test-Group { $false }
            Mock Write-Error {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' | Should Be $false
        }
        It 'Fails on existing group with new name' {
            Mock Test-Group { $true }
            Mock Write-Error {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' | Should Be $false
        }
        It 'Completes on successful AD operations' {
            Mock Test-Group { $true  } -ParameterFilter {$Identity -eq 'MyGroup'}
            Mock Test-Group { $false } -ParameterFilter {$Identity -eq 'MyNewGroup'}
            Mock Get-ADGroup { 
                [pscustomobject]@{
                    DistinguishedName = 'CN=MyGroup,DC=mydomain,DC=local'
                    GroupCategory     = 'Security'
                    GroupScope        = 'Global'
                    Name              = 'MyGroup'
                    ObjectClass       = 'group'
                    ObjectGUID        = '00000000-0000-0000-0000-000000000000'
                    SamAccountName    = 'MyGroup'
                    SID               = 'S-1-5-21-0000000000-0000000000-0000000000-0000'
                }
            }
            Mock Set-ADGroup {}
            Mock Rename-ADObject {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' #| Should Be $true
            Assert-MockCalled Set-ADGroup -Times 1
            Assert-MockCalled Rename-ADObject -Times 1
        }
        It 'Fails on first failed AD operation' {
            Mock Test-Group { $true  } -ParameterFilter {$Identity -eq 'MyGroup'}
            Mock Test-Group { $false } -ParameterFilter {$Identity -eq 'MyNewGroup'}
            Mock Get-ADGroup { throw }
            Mock Set-ADGroup {}
            Mock Rename-ADObject {}
            Mock Write-Error {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' | Should Be $false
        }
        It 'Fails on second failed AD operation' {
            Mock Test-Group { $true  } -ParameterFilter {$Identity -eq 'MyGroup'}
            Mock Test-Group { $false } -ParameterFilter {$Identity -eq 'MyNewGroup'}
            Mock Get-ADGroup {}
            Mock Set-ADGroup { throw }
            Mock Rename-ADObject {}
            Mock Write-Error {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' | Should Be $false
        }
        It 'Fails on second failed AD operation' {
            Mock Test-Group { $true  } -ParameterFilter {$Identity -eq 'MyGroup'}
            Mock Test-Group { $false } -ParameterFilter {$Identity -eq 'MyNewGroup'}
            Mock Get-ADGroup {}
            Mock Set-ADGroup {}
            Mock Rename-ADObject { throw }
            Mock Write-Error {}
            Rename-ADGroup -Identity 'MyGroup' -NewName 'MyNewGroup' | Should Be $false
        }
    }
    Context 'Wait-ADGroup' {}
    Context 'Add-Permission' {}
}