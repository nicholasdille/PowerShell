$Servers = @(
    'sql-01.demo.dille.name'
)

foreach ($Server in $Servers) {
    $Session = New-PSSession -ComputerName $Server -Authentication Credssp -Credential (Get-Credential)
    Invoke-Command -Session $Session -ScriptBlock {
        & '\\srv2\c$\Users\administrator.DEMO\OneDrive\Scripts\PowerShell\Windows Update\Install-WindowsUpdate-Worker.ps1'
    }
}