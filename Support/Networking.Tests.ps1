$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
. "$here\$sut"

#Requires -Modules ActiveDirectory

Describe 'Get-Fqdn' {
    $NameArray = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name -First 2
    $FqdnArray = @('', '')

    It 'works for a single host parameter' {
        $FqdnArray[0] = Get-Fqdn -ComputerName $NameArray[0]
        $FqdnArray[0] -like "$($NameArray[0]).*" | Should Be $true
    }
    It 'works for a single host pipeline' {
        $FqdnArray[0] = $NameArray[0] | Get-Fqdn
        $FqdnArray[0] -like "$($NameArray[0]).*" | Should Be $true
    }
    It 'does not choke on FQDN parameter' {
        Get-Fqdn -ComputerName $FqdnArray[0] | Should Be $FqdnArray[0]
    }
    It 'does not choke on FQDN pipeline' {
        $FqdnArray[0] | Get-Fqdn | Should Be $FqdnArray[0]
    }
    It 'works for a host array parameter' {
        $FqdnArray = Get-Fqdn -ComputerName $NameArray
        $FqdnArray.Length | Should Be 2
        $FqdnArray -icontains $NameArray[0] | Should Be $true
        $FqdnArray -icontains $NameArray[1] | Should Be $true
    }
    It 'works for a host array pipeline' {
        $FqdnArray = $NameArray | Get-Fqdn
        $FqdnArray.Length | Should Be 2
        $FqdnArray -icontains $NameArray[0] | Should Be $true
        $FqdnArray -icontains $NameArray[1] | Should Be $true
    }
}