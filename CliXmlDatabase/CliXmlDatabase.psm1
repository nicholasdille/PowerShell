#Requires -Version 4
Set-StrictMode -Version 4

#TODO: Comment-based Help, Pipeline, Dirty-Flag

$Connections = @()

function New-CliXmlDatabase {
    <#
        .SYNOPSIS
        Creates a new CliXml based database

        .DESCRIPTION
        Creates the directory to hold the CliXml based database

        .PARAMETER Path
        Path to the directory

        .EXAMPLE
        New-CliXmlDatabase -Path .\CliXmlDatabase

        .LINK
        http://dille.name/blog
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        if (Test-CliXmlDatabase -Path $Path) {
            throw ('[{0}] Database at path "{1}" already exists. Aborting.' -f $MyInvocation.MyCommand, $Path)
        }
        if ($Force -or $PSCmdlet.ShouldProcess("Create new database directory at '$Path'")) {
            $ConfirmPreference = 'None'
            New-Item -Path $Path -ItemType Directory -Force:$Force | Out-Null
        }
    }
}

function Test-CliXmlDatabase {
    <#
        .SYNOPSIS
        Tests whether a CliXml based database exists

        .DESCRIPTION
        Tests for the existence of a directory

        .PARAMETER Path
        Path to the directory

        .EXAMPLE
        Test-CliXmlDatabase -Path .\CliXmlDatabase

        .LINK
        http://dille.name/blog
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Write-Verbose -Message ('[{0}] Testing for existence of path "{1}"' -f $MyInvocation.MyCommand, $Path)
        Test-Path -Path $Path
    }
}

function Assert-CliXmlDatabase {
    <#
        .SYNOPSIS
        Makes sure that a CliXml database exists

        .DESCRIPTION
        Throws if the directory does not exist

        .PARAMETER Path
        Path to the directory

        .EXAMPLE
        Assert-CliXmlDatabase -Path .\CliXmlDatabase

        .LINK
        http://dille.name/blog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        if (-not (Test-CliXmlDatabase -Path $Path)) {
            throw ('[{0}] Database at path "{1}" does not exist' -f $MyInvocation.MyCommand, $Path)
        }
    }
}

function Open-CliXmlDatabase {
    <#
        .SYNOPSIS
        Opens a CliXml based database

        .DESCRIPTION
        Read a CliXml based database into memory

        .PARAMETER ConnectionName
        Name of the database connection

        .PARAMETER Path
        Path to the directory

        .EXAMPLE
        Open-CliXmlDatabase -Name Test -Path .\CliXmlDatabase

        .LINK
        http://dille.name/blog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        if (Test-CliXmlDatabaseConnection -ConnectionName $ConnectionName) {
            throw ('[{0}] Connection name "{1}" is already in use' -f $MyInvocation.MyCommand, $ConnectionName)
        }

        $NewConnection = @{
            Name = $ConnectionName
            Path = $Path
            Data = @{}
        }
        $Tables = @{}
        Get-ChildItem -Path $Path | Where-Object {$_.Extension -ieq '.clixml'} | ForEach-Object {
            Write-Verbose -Message ('[{0}] Adding table {1}' -f $MyInvocation.MyCommand, $_.BaseName)
            $Tables.Add($_.BaseName, $_.Name)
        }
        foreach ($TableName in $Tables.Keys) {
            Write-Verbose -Message ('[{0}] Importing into table "{1}"' -f $MyInvocation.MyCommand, $TableName)
            $NewConnection['Data'][$TableName] = @{}
            Import-Clixml -Path "$Path\$($Tables[$TableName])" | ForEach-Object {
                if ($_ -ne $null) {
                    $NewConnection['Data'][$TableName].Add($_.Id, $_)
                }
            }
        }
        $Script:Connections += $NewConnection
    }
}

function Save-CliXmlDatabase {
    <#
            .SYNOPSIS
            Saves a CliXml based database

            .DESCRIPTION
            All tables of the CliXml based database are written to disk

            .PARAMETER ConnectionName
            Name of the database connection

            .EXAMPLE
            Save-CliXmlDatabase -ConnectionName Test

            .LINK
            http://dille.name/blog
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        if ($Force -or $PSCmdlet.ShouldProcess("Flush database '$ConnectionName' to disk")) {
            $ConfirmPreference = 'None'
            
            $Tables = $Connection.Data.Keys
            $Path = $Connection.Path
            foreach ($TableName in $Tables) {
                $Connection.Data[$TableName].Values | Export-Clixml -Path "$Path\$TableName.clixml"
            }
        }
    }
}

function Close-CliXmlDatabase {
    <#
        .SYNOPSIS
        Closes the connection to a CliXml based database

        .DESCRIPTION
        XXX

        .PARAMETER ConnectionName
        Name of the database connection

        .PARAMETER Discard
        Whether to save the tables to disk

        .EXAMPLE
        Close-CliXmlDatabase -ConnectionName Test

        .EXAMPLE
        Close-CliXmlDatabase -ConnectionName Test -Discard

        .LINK
        http://dille.name/blog
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter()]
        [switch]
        $Discard
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        if (-not $Discard) {
            Save-CliXmlDatabase -ConnectionName $ConnectionName
        }
        $Script:Connections = $Connections | Where-Object {$_.Name -ine $ConnectionName}
    }
}

function Remove-CliXmlDatabase {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        if ($Connections | Where-Object {$_.Path -ieq $Path}) {
            throw ('[{0}] Database at path "{1}" is opened' -f $MyInvocation.MyCommand, $Path)
        }
        if ($Force -or $PSCmdlet.ShouldProcess("Remove database at path '$Path'")) {
            $ConfirmPreference = 'None'
            
            Remove-Item -Path $Path -Recurse -Force:$Force
        }
    }
}

function Get-CliXmlDatabaseConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        $Connections | Where-Object {$_.Name -ieq $ConnectionName}
    }
}

function Test-CliXmlDatabaseConnection {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        @(Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName).Count -gt 0
    }
}

function Assert-CliXmlDatabaseConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        if (-not (Test-CliXmlDatabaseConnection -ConnectionName $ConnectionName)) {
            throw ('[{0}] Connection "{1}" does not exist' -f $MyInvocation.MyCommand, $ConnectionName)
        }
    }
}

function New-CliXmlDatabaseTable {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        if (Test-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName) {
            throw ('[{0}] Table "{1}" already exists' -f $MyInvocation.MyCommand, $TableName)
        }

        if ($Force -or $PSCmdlet.ShouldProcess("Create new table '$TableName' in database '$ConnectionName' and write to disk")) {
            $ConfirmPreference = 'None'
        
            $TableFile = "$($Connection.Path)\$TableName.clixml"
            $Connection.Data.Add($TableName, @{})
            $null | Export-Clixml -Path $TableFile -Force:$Force
        }
    }
}

function Test-CliXmlDatabaseTable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        $TableFile = "$($Connection.Path)\$TableName.clixml"

        $Connection.Data.Keys -icontains $TableName -and (Test-Path -Path $TableFile)
    }
}

function Assert-CliXmlDatabaseTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        if (-not (Test-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName)) {
            throw ('[{0}] Table "{1}" does not exist' -f $MyInvocation.MyCommand, $TableName)
        }
    }
}

function Get-CliXmlDatabaseTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName

        $Connection.Data.Keys
    }
}

function Clear-CliXmlDatabaseTable {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        if ($Force -or $PSCmdlet.ShouldProcess("Remove data from table '$TableName' in database '$ConnectionName'")) {
            $ConfirmPreference = 'None'
            
            $Connection.Data[$TableName] = @{}
        }
    }
}

function Remove-CliXmlDatabaseTable {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        if ($Force -or $PSCmdlet.ShouldProcess("Remove table '$TableName' from memory copy database '$ConnectionName'")) {
            $ConfirmPreference = 'None'
            
            $Connection.Data.Remove($TableName)
        }
    }
}

function Get-CliXmlDatabaseTableKey {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        if ($Connection.Data[$TableName].Count -eq 0) {
            0

        } else {
            $Id = $Connection.Data[$TableName].Keys | Sort-Object -Descending | Select-Object -First 1
            $Id + 1
        }
    }
}

function Assert-CliXmlDatabaseTableField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [array]
        $Key
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        $Item = Get-CliXmlDatabaseItem -ConnectionName $ConnectionName -TableName $TableName -Id 0
        if (-not $Item) {
            Write-Verbose -Message ('[{0}] Table {1} is empty' -f $MyInvocation.MyCommand, $TableName)
            return
        }

        Write-Verbose -Message ('[{0}] Got item {1}' -f $MyInvocation.MyCommand, $Item)
        $FieldNames = $Item.PSObject.Properties.Name
        foreach ($FieldName in $Key) {
            Write-Verbose -Message ('[{0}] Testing key {1} against {2}' -f $MyInvocation.MyCommand, $FieldName, ($FieldNames -join ','))
            if ($FieldNames -inotcontains $FieldName) {
                throw ('[{0}] Existing data does not contain key "{1}" of specified data' -f $MyInvocation.MyCommand, $FieldName)
            }
        }
    }
}

function New-CliXmlDatabaseItem {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $Data
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName
        Assert-CliXmlDatabaseTableField -ConnectionName $ConnectionName -TableName $TableName -Key $Data.Keys

        if ($Force -or $PSCmdlet.ShouldProcess("Add new item to table '$TableName' in database '$ConnectionName'")) {
            $ConfirmPreference = 'None'
            
            Write-Verbose -Message ('[{0}] Retrieving new key' -f $MyInvocation.MyCommand)
            $NewId = Get-CliXmlDatabaseTableKey -ConnectionName $ConnectionName -TableName $TableName

            Write-Verbose -Message ('[{0}] Get key {1}' -f $MyInvocation.MyCommand, $NewId)
            $Data.Add('Id', $NewId)

            Write-Verbose -Message ('[{0}] Creating item from data' -f $MyInvocation.MyCommand)
            $Item = [pscustomobject]$Data
            Write-Verbose -Message ('[{0}] Adding item to table' -f $MyInvocation.MyCommand)
            $Connection.Data[$TableName].Add($NewId, $Item)

            Write-Verbose -Message ('[{0}] Returning item with ID {1}' -f $MyInvocation.MyCommand, $NewId)
            $Item
        }
    }
}

function Get-CliXmlDatabaseItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        if ($Connection.Data[$TableName].Count -eq 0) {
            return
        }

        if ($PSBoundParameters.ContainsKey('Id')) {
            $Connection.Data[$TableName].Item($Id)
                
        } else {
            $Connection.Data[$TableName].Values
        }
    }
}

function Set-CliXmlDatabaseItem {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]
        $Data
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName
        Assert-CliXmlDatabaseTableField -ConnectionName $ConnectionName -TableName $TableName -Key $Data.Keys

        if ($Force -or $PSCmdlet.ShouldProcess("Set fields on item in table '$TableName' in database '$ConnectionName'")) {
            $ConfirmPreference = 'None'
            
            $Item = Get-CliXmlDatabaseItem -Connection $ConnectionName -Table $TableName -Id $Id
            foreach ($FieldName in $Data.Keys) {
                $Item.$FieldName = $Data[$FieldName]
            }
        }
    }
}

function Remove-CliXmlDatabaseItem {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Low')]
    param(
        [Parameter(Mandatory)]
        [Alias('Name', 'Connection')]
        [ValidateNotNullOrEmpty()]
        [string]
        $ConnectionName
        ,
        [Parameter(Mandatory)]
        [Alias('Table')]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter()]
        [switch]
        $Force
    )

    Begin {
        if (-not $PSBoundParameters.ContainsKey('Verbose')) {
            $VerbosePreference = $PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference')
        }
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    Process {
        Assert-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        $Connection = Get-CliXmlDatabaseConnection -ConnectionName $ConnectionName
        Assert-CliXmlDatabaseTable -ConnectionName $ConnectionName -TableName $TableName

        if ($Force -or $PSCmdlet.ShouldProcess("Remove item from table '$TableName' in database '$ConnectionName'")) {
            $ConfirmPreference = 'None'
            
            $Connection.Data[$TableName].Remove($Id)
        }
    }
}