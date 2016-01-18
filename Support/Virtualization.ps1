#Requires -Modules Hyper-V
#, VirtualMachineManager

function Show-IPAddress {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='NewCimSession')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(ParameterSetName='NewCimSession')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(ParameterSetName='ExistingCimSession')]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession]
        $CimSession
    )

    Begin {
        $Params = @{}
        if ($CimSession) {
            $Params['CimSession'] = $CimSession

        } else {
            $CimParams = @{}
            if ($ComputerName) { $CimParams['ComputerName'] = $ComputerName }
            if ($Credential)   { $CimParams['Credential']   = $Credential }
            if ($CimParams.Keys) {
                try {
                    $Params['CimSession'] = New-CimSession @CimParams

                } catch {
                    throw ('[{0}] Unable to establish CIM connection' -f $MyInvocation.MyCommand)
                }
            }
        }
    }

    Process {
        $NetAdapter = Get-NetAdapter @Params
        Get-NetIPAddress @Params | Where-Object {$_.AddressFamily -eq 'IPv4'} | ForEach-Object {
            $IPAddress = $_
            $Adapter = $NetAdapter | Where-Object {$_.InterfaceIndex -eq $IPAddress.InterfaceIndex}
            [pscustomobject]@{
                InterfaceIndex = $IPAddress.InterfaceIndex
                InterfaceAlias = $IPAddress.InterfaceAlias
                MacAddress     = $Adapter.MacAddress
                Status         = $Adapter.Status
                LinkSpeed      = $adapter.LinkSpeed
                IPAddress      = $IPAddress.IPv4Address
            }
        }
    }
}

function Rename-NetAdapterSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $NetAdapter
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NamePrefix
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $StartIndex = 0
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession]
        $CimSession
    )

    Begin {
        $Params = @{}
        if ($CimSession) {
            $Params['CimSession'] = $CimSession

        } else {
            $CimParams = @{}
            if ($ComputerName) { $CimParams['ComputerName'] = $ComputerName }
            if ($Credential)   { $CimParams['Credential']   = $Credential }
            if ($CimParams.Keys) {
                try {
                    $Params['CimSession'] = New-CimSession @CimParams

                } catch {
                    throw ('[{0}] Unable to establish CIM connection' -f $MyInvocation.MyCommand)
                }
            }
        }

        $Index = $StartIndex
        $Length = ([string]$NetAdapter.Count).Length
    }

    Process {
        ForEach ($AdapterName in $NetAdapter) {
            $NewName = '0' * ($Length - ([string]$Index).Length)
            $NewName = "$NamePrefix$NewName$Index"
            Rename-NetAdapter @Params -Name $AdapterName -NewName "$NewName"
            ++$Index
        }
    }
}

function New-NetAdapterTeam {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $NetAdapter
        ,
        [Parameter()]
        [ValidateSet('Lacp', 'Static', 'SwitchIndependent')]
        [string]
        $Mode = 'SwitchIndependent'
        ,
        [Parameter()]
        [ValidateSet('Dynamic', 'HyperVPort', 'IPAddresses', 'MacAddresses', 'TransportPorts')]
        [string]
        $Algorithm = 'Dynamic'
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Microsoft.Management.Infrastructure.CimSession]
        $CimSession
    )

    Begin {
        $Params = @{}
        if ($CimSession) {
            $Params['CimSession'] = $CimSession

        } else {
            $CimParams = @{}
            if ($ComputerName) { $CimParams['ComputerName'] = $ComputerName }
            if ($Credential)   { $CimParams['Credential']   = $Credential }
            if ($CimParams.Keys) {
                try {
                    $Params['CimSession'] = New-CimSession @CimParams

                } catch {
                    throw ('[{0}] Unable to establish CIM connection' -f $MyInvocation.MyCommand)
                }
            }
        }
    }

    Process {
        New-NetLbfoTeam @Params -Name $Name -TeamMembers $NetAdapter -TeamingMode $Mode -LoadBalancingAlgorithm $Algorithm
    }
}

function New-VirtualSwitch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $NetAdapter
        ,
        [Parameter()]
        [ValidateSet('Absolute', 'Default', 'None', 'Weight')]
        [string]
        $QosMode = 'Weight'
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )

    Begin {
        $CimParams = @{}
        if ($ComputerName) { $CimParams['ComputerName'] = $ComputerName }
        if ($Credential)   { $CimParams['Credential']   = $Credential }
        $Params = @{}
        if ($CimParams.Keys) {
            try {
                $Params['CimSession'] = New-CimSession @CimParams

            } catch {
                throw ('[{0}] Unable to establish CIM connection' -f $MyInvocation.MyCommand)
            }
        }
    }

    Process {
        New-VMSwitch @Params -Name $Name -NetAdapterName $NetAdapter -MinimumBandwidthMode $QosMode
        Select ($QosMode) {
            Weight   { Set-VMSwitch -Name $Name -DefaultFlowMinimumBandwidthWeight 50 }
            Absolute { Set-VMSwitch -Name $Name -DefaultFlowMinimumBandwidthAbsolute 0 }
        }
    }
}

function New-ManagementAdapter {
    [CmdletBinding()]
    param()

    Process {
        Add-VMNetworkAdapter -ManagementOS -Name '' -SwitchName ''
        Set-VMNetworkAdapter -ManagementOS -Name '' -
    }
}

function New-HyperVVM {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParentPath
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SwitchName
    )

    Process {
        $Vhd = New-VHD -Differencing -Path $Path -ParentPath $ParentPath
        New-VM -Name $Name -MemoryStartupBytes 2048MB -VHDPath $Vhd -SwitchName $SwitchName -Generation 2
        Set-VM -Name $Name -ProcessorCount 2
        
        Enable-VMIntegrationService  -VMName $Name -Name 'Heartbeat'
        Enable-VMIntegrationService  -VMName $Name -Name 'Key-Value Pair Exchange'
        Enable-VMIntegrationService  -VMName $Name -Name 'Shutdown'
        Enable-VMIntegrationService  -VMName $Name -Name 'VSS'
        Enable-VMIntegrationService  -VMName $Name -Name 'Guest Service Interface'
        Disable-VMIntegrationService -VMName $Name -Name 'Time Synchronization'
    }
}

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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $VMMServer
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $VmName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $IPv4Pattern = '^\d+\.\d+\.\d+\.\d+$'
    )

    (Get-VM -ComputerName $ComputerName -Name $VmName).NetworkAdapters[0].IPAddresses | Where-Object { $_ -match $IPv4Pattern } | Select-Object -First 1
}

function Optimize-VirtualDisk {
    Param(
        [string]
        $Path
    )

    Mount-VHD -Path "$Path" -ReadOnly
    Optimize-VHD -Path "$Path" -Mode Full
    Dismount-VHD -Path "$Path"
}

function Set-HyperVPermissions {
    $ConfigDir = 'F:\Configuration\Virtual Machines'

    Get-ChildItem -Directory $ConfigDir | foreach {
	    $VmGuid = $_.Name

	    cmd icacls "$ConfigDir\$VmGuid.xml" /grant "NT VIRTUAL MACHINE\$VmGuid":(F) /L
	    cmd icacls F:\ /T /grant "NT VIRTUAL MACHINE\$VmGuid":(F)
    }
}