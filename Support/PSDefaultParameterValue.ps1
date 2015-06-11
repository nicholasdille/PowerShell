function Backup-DefaultParameterValues {
    [CmdletBinding()]
    param()

    PROCESS {
        $Script:BackupOf_PSDefaultParameterValues = $PSDefaultParameterValues
    }
}

function Get-DefaultParameterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CmdletName
        ,
        [Parameter(Mandatory=$true)]
        [Alias('Parameter')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParameterName
    )

    PROCESS {
        $PSDefaultParameterValues."$($CmdletName):$ParameterName"
    }
}

function Set-DefaultParameterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CmdletName
        ,
        [Parameter(Mandatory=$true)]
        [Alias('Parameter')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParameterName
        ,
        [Parameter(Mandatory=$true)]
        [Alias('Value')]
        $ParameterValue
    )

    PROCESS {
        $PSDefaultParameterValues."$($CmdletName):$ParameterName" = $ParameterValue
    }
}

function Remove-DefaultParameterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [ValidateNotNullOrEmpty()]
        [string]
        $CmdletName
        ,
        [Parameter(Mandatory=$true)]
        [Alias('Parameter')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ParameterName
    )

    PROCESS {
        $PSDefaultParameterValues.Remove("$($CmdletName):$ParameterName")
    }
}

function Restore-DefaultParameterValues {
    [CmdletBinding()]
    param()

    PROCESS {
        $PSDefaultParameterValues = $Script:BackupOf_PSDefaultParameterValues
    }
}