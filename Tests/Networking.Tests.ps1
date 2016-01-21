$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

#Requires -Modules ActiveDirectory

Describe 'Networking' {
    Context 'Get-Fqdn' {
        $DnsNames = @{
            'dc-01' = 'dc-01.mydomain.local'
            'dc-02' = 'dc-02.mydomain.local'
        }
        Mock Resolve-DnsName {
            [pscustomobject]@{Name = $DnsNames['dc-01']}
        } -ParameterFilter {$Name -like 'dc-01*'}
        Mock Resolve-DnsName {
            [pscustomobject]@{Name = $DnsNames['dc-02']}
        } -ParameterFilter {$Name -like 'dc-02*'}

        It 'works for a single host parameter' {
            $Result = Get-Fqdn -ComputerName 'dc-01'
            $Result -is [array] | Should Be $false
            $Result | Should Be $DnsNames['dc-01']
        }
        It 'works for a single host in the pipeline' {
            $Result = 'dc-01' | Get-Fqdn
            $Result -is [array] | Should Be $false
            $Result | Should Be $DnsNames['dc-01']
        }
        It 'does not choke on FQDN parameter' {
            Get-Fqdn -ComputerName $DnsNames['dc-01'] | Should Be $DnsNames['dc-01']
        }
        It 'does not choke on FQDN in the pipeline' {
            $DnsNames['dc-01'] | Get-Fqdn | Should Be $DnsNames['dc-01']
        }
        It 'works for a host array parameter' {
            $Result = Get-Fqdn -ComputerName 'dc-01', 'dc-02'
            $Result -is [array] | Should Be $true
            $Result.Length | Should Be 2
            $Result -icontains $DnsNames['dc-01'] | Should Be $true
            $Result -icontains $DnsNames['dc-02'] | Should Be $true
        }
        It 'works for a host array in the pipeline' {
            $Result = 'dc-01', 'dc-02' | Get-Fqdn
            $Result -is [array] | Should Be $true
            $Result.Length | Should Be 2
            $Result -icontains $DnsNames['dc-01'] | Should Be $true
            $Result -icontains $DnsNames['dc-02'] | Should Be $true
        }
    }
}