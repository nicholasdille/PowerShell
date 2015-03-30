Set-StrictMode -Version Latest

function Get-VmIdFromHyperV {
    <#
    .SYNOPSIS
    Get the unique ID for a virtual machine running on Hyper-V

    .DESCRIPTION
    Every virtual machine has a property called ID containing a GUID

    .PARAMETER ComputerName
    The name of the Hyper-V host

    .PARAMETER Name
    The name of the VM

    .EXAMPLE
    Get-VmIdFromHyperV -ComputerName hv-01 -Name DSC-01
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    (Get-VM @PSBoundParameters | Select-Object Id).Id
}

function Get-VmIdFromVmm {
    <#
    .SYNOPSIS
    Get the unique ID for a virtual machine managed by System Center Virtual Machine Manager

    .DESCRIPTION
    Every virtual machine has a property called ID containing a GUID

    .PARAMETER VMMServer
    The name of the VMM management server

    .PARAMETER Name
    The name of the VM

    .EXAMPLE
    Get-VmIdFromVmm -VMMServer vmm-01 -Name DSC-01

    .NOTES
    This function requires the SCVMM PowerShell cmdlets which come with the console installation
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$VMMServer
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    (Get-SCVirtualMachine @PSBoundParameters | Select-Object Id).Id
}

function Get-VmIp {
    <#
    .SYNOPSIS
    Get the IPv4 address of the first network adapter of a VM running on Hyper-V

    .PARAMETER ComputerName
    The name of the Hyper-V host

    .PARAMETER VmName
    The name of the VM

    .PARAMETER IPv4Pattern
    Regular expression for an matching IPv4 address

    .EXAMPLE
    Get-VmIp -ComputerName hv-01 -VmName DSC-01

    .NOTES
    This function assumes that the first network adapter is used for management access
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $VmName
        ,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPv4Pattern = '^\d+\.\d+\.\d+\.\d+$'
    )

    (Get-VM -ComputerName $ComputerName -Name $VmName).NetworkAdapters[0].IPAddresses | Where-Object { $_ -match $IPv4Pattern } | Select-Object -First 1
}