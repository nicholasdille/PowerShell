function Get-Fqdn {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName
    )

    PROCESS {
        foreach ($Name in $ComputerName) {
            Resolve-DnsName -Name $Name -Type A | Select-Object -ExpandProperty Name
        }
    }
}