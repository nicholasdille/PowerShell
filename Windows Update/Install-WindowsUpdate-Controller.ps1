$Servers = @(
    'sql-02.demo.dille.name'
)

foreach ($Server in $Servers) {
    $Session = New-PSSession -ComputerName $Server -Authentication Credssp -Credential (Import-Clixml -Path (Join-Path -Path $PSScriptRoot -ChildPath 'administrator@DEMO.clixml'))
    Invoke-Command -Session $Session -ScriptBlock {
        & '\\srv2\c$\Users\administrator.DEMO\OneDrive\Scripts\PowerShell\Install-WindowsUpdate-Worker.ps1'
    }
}