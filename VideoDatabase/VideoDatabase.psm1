Import-Module -Name "$PSScriptRoot\..\..\PowerShell\CliXmlDatabase\CliXmlDatabase.psm1" -Force

#TODO: Comment-based help, pipe, ShouldProcess

#region Database management
Function New-VideoDatabase {
    [CmdletBinding()]
    Param(
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
        New-CliXmlDatabase -Path $Path
        Open-CliXmlDatabase -ConnectionName 'VideoDatabase' -Path $Path
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Location'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Person'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Tag'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'TagToVideo'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Playlist'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist'
        New-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Bookmark'
        Close-CliXmlDatabase -ConnectionName 'VideoDatabase'
    }
}

Function Open-VideoDatabase {
    [CmdletBinding()]
    Param(
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
        Open-CliXmlDatabase -ConnectionName 'VideoDatabase' -Path $Path
    }
}

Function Close-VideoDatabase {
    [CmdletBinding()]
    Param()

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
        Close-CliXmlDatabase -ConnectionName 'VideoDatabase'
    }
}

Function Import-Video {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $TagName = (Get-Date).ToString('yyyyMMddHHmmss')
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
        if (-not (Test-Tag -Name $TagName)) {
            Write-Verbose ('[{0}] Creating new tag called {1}' -f $MyInvocation.MyCommand, $TagName)
            $Tag = New-Tag -Name "$TagName"

        } else {
            Write-Verbose ('[{0}] Retrieving tag called {1}' -f $MyInvocation.MyCommand, $TagName)
            $Tag = Get-Tag -Name $TagName
        }
        Write-Verbose ('[{0}] Using tag ID {1}' -f $MyInvocation.MyCommand, $Tag.Id)

        $Path | ForEach-Object {
            Write-Verbose ('[{0}] Processing path "{1}"' -f $MyInvocation.MyCommand, $_)
            if (-not (Test-VideoFile -Path $_)) {
                Write-Verbose ('[{0}] Adding video file')
                $File = New-VideoFile -Path $_
                New-Video -FileId $File.Id
                Add-VideoTag -VideoId $File.Id -TagId $Tag.Id | Out-Null
            }
        }
    }
}

Function Import-VideoLocation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-VideoLocation -Path $Path) {
            Write-Verbose ('[{0}] Retrieving location from path {1}' -f $MyInvocation.MyCommand, $Path)
            $Location = Get-VideoLocation -Path $Path

        } else {
            Write-Verbose ('[{0}] Creating new location {1} for path {2}' -f $MyInvocation.MyCommand, $Name, $Path)
            $Location = New-VideoLocation -Name $Name -Path $Path
        }
        Write-Verbose ('[{0}] Using location ID {1}' -f $MyInvocation.MyCommand, $Location.Id)

        $TagName = (Get-Date).ToString('yyyyMMddHHmmss')
        Write-Verbose ('[{0}] Creating new tag called {1}' -f $MyInvocation.MyCommand, $TagName)
        New-Tag -Name $TagName | Out-Null

        Get-ChildItem -Path $Path -Recurse -File | Select-Object -ExpandProperty FullName | Import-Video -TagName $TagName
    }
}
#endregion

#region Universal Functions
Function Remove-VideoDatabaseItem {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TableName
        ,
        [Parameter(Mandatory)]
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
        Remove-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName $TableName -Id $Id
    }
}

Function Out-HashTable {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [hashtable[]]
        $InputObject
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Prefix = ''
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
        $InputObject | ForEach-Object {
            Out-PSCustomObject -InputObject ([pscustomobject]$_) -Prefix $Prefix
        }
    }
}

Function Out-PSCustomObject {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [psobject[]]
        $InputObject
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Prefix = ''
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
        $InputObject | ForEach-Object {
            $Item = $_

            $Result = "$Prefix@{"
            $Result += ($Item.PSObject.Properties.Name | ForEach-Object {
                    "$_=$($Item.$_)"
            }) -join ', '
            $Result += '}'
            $Result
        }
    }
}
#endregion

#region Location management
Function Test-VideoLocation {
    [CmdletBinding()]
    Param(
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
        @(Get-VideoLocation -Path $Path).Count -eq 1
    }
}

Function New-VideoLocation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        Write-Verbose ('[{0}] Processing' -f $MyInvocation.MyCommand)
        $Locations = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location')
        foreach ($Location in $Locations) {
            Write-Verbose ('[{0}] Processing location called {1} at {2}' -f $MyInvocation.MyCommand, $Location.Name, $Location.Path)
            if ($Location.Name -ieq $Name) {
                Write-Verbose ('[{0}] Location with identical name ({1}) already exists' -f $MyInvocation.MyCommand, $Name)
                $Location
                return
            }
            if ($Location.Path -ieq $Path) {
                Write-Verbose ('[{0}] Location with identical path ({1}) already exists' -f $MyInvocation.MyCommand, $Path)
                $Location
                return
            }
            Write-Verbose ('[{0}] Done with location')
        }

        Write-Verbose ('[{0}] Creating new location' -f $MyInvocation.MyCommand)
        $Location = New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location' -Data @{
            Name      = $Name
            Path      = $Path
        }

        Write-Verbose ('[{0}] Returning location with ID {1}' -f $MyInvocation.MyCommand, $Location.Id)
        $Location
    }
}

Function Get-VideoLocation {
    [CmdletBinding(DefaultParameterSetName='GetAll')]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='GetByPath', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location' -Id $Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByName') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location' | Where-Object {$_.Name -ieq $Name}

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByPath') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location' | Where-Object {$_.Path -ieq $Path}

        } else {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location'
        }
    }
}

Function Find-VideoLocation {
    [CmdletBinding()]
    Param(
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
        $Locations = @(Get-VideoLocation -All)
        foreach ($Location in $Locations) {
            Write-Verbose ('[{0}] Testing "{1}" against "{2}"' -f $MyInvocation.MyCommand, $Path.Substring(0, $Location.Path.Length), $Location.Path)
            if ($Path.Substring(0, $Location.Path.Length) -ieq $Location.Path) {
                Write-Verbose ('[{0}] Match found with location called {1}' -f $MyInvocation.MyCommand, $Location.Name)
                $Location
                return
            }
        }
    }
}

Function Set-VideoLocation {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='SetName', Mandatory)]
        [Parameter(ParameterSetName='SetPath', Mandatory)]
        [Parameter(ParameterSetName='SetNameAndPath', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='SetName', Mandatory)]
        [Parameter(ParameterSetName='SetNameAndPath', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='SetPath', Mandatory)]
        [Parameter(ParameterSetName='SetNameAndPath', Mandatory)]
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
        $Location = Get-VideoLocation -Id $Id
        if ($Name) {
            $Location.Name = $Name
        }
        if ($Path) {
            $Location.Path = $Path
        }
    }
}

Function Remove-VideoLocation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Remove-VideoDatabaseItem -TableName 'Location' -Id $Id
    }
}
#endregion

#region File management
Function Split-VideoFile {
    [CmdletBinding()]
    Param(
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
        $VideoLocation = Find-VideoLocation -Path $Path
        if (-not $VideoLocation) {
            throw ('[{0}] Video file lives in an unknown location ({1})' -f $MyInvocation.MyCommand, $Path)
        }

        if ($Path -match '^(.+\\)((.+)\.([^\.]+))$') {
            $FileBaseName = $Matches[3]
            $FileName = $Matches[2]
            $FilePath = $Matches[1]

        } else {
            throw ('[{0}] Unable to parse path "{1}"' -f $MyInvocation.MyCommand, $Path)
        }

        @{
            LocationId = $VideoLocation.Id
            Path = $Path
            FileBaseName = $FileBaseName
            FileName = $FileName
            FilePath = $FilePath
            SubPath = $FilePath.Substring($VideoLocation.Path.Length)
        }
    }
}

Function Test-VideoFile {
    [CmdletBinding()]
    Param(
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
        $Data = Split-VideoFile -Path $Path
        $VideoLocation = Get-VideoLocation -Id $Data.LocationId
        Write-Verbose ('[{0}] Looking for video file with name "{1}" in location "{2}={3}" and path "{4}"' -f $MyInvocation.MyCommand, $Data.FileName, $VideoLocation.Id, $VideoLocation.Path, $Data.SubPath)
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' | ForEach-Object {
            Write-Verbose ('[{0}] Checking file {1}' -f $MyInvocation.MyCommand, ($_ | Out-PSCustomObject -Prefix 'File='))
            if ($_.LocationId -eq $VideoLocation.Id -and $_.Path -ieq $Data.SubPath -and $_.FileName -ieq $Data.FileName) {
                Write-Verbose ('[{0}] Found file with path "{1}"' -f $MyInvocation.MyCommand, $Path)
                $Result = $true
            }
        }

        $Result
    }
}

Function New-VideoFile {
    [CmdletBinding()]
    Param(
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
        $VideoLocation = Find-VideoLocation -Path $Path
        if (-not $VideoLocation) {
            throw ('[{0}] Video file lives in an unknown location ({1})' -f $MyInvocation.MyCommand, $Path)
        }

        if (Test-VideoFile -Path $Path) {
            Write-Verbose ('[{0}] Video file "{1}" already exists' -f $MyInvocation.MyCommand, $Path)
            return
        }

        $Data = Split-VideoFile -Path $Path

        $CreationTimeTicks = -1
        if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
            Write-Verbose ('[{0}] Getting info from item' -f $MyInvocation.MyCommand)
            $File = Get-Item -Path $Path
            $CreationTimeTicks = $File.CreationTime.Ticks
        }
        $ItemData = @{
            LocationId = $Data.LocationId
            Name       = $Data.FileBaseName
            FileName   = $Data.FileName
            Path       = $Data.SubPath
            FullPath   = $Path
            Timestamp  = $CreationTimeTicks
        }
        Write-Verbose ('[{0}] Adding data {1}' -f $MyInvocation.MyCommand, ($ItemData | Out-HashTable -Prefix 'Data:'))
        $File = New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' -Data $ItemData

        Write-Verbose ('[{0}] Returning file' -f $MyInvocation.MyCommand)
        $File
    }
}

Function Get-VideoFile {
    [CmdletBinding(DefaultParameterSetName='GetAll')]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='GetByPath', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' -Id $Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByName') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' | Where-Object {$_.Name -ieq $Name}

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByPath') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' | Where-Object {$_.Path -ieq $Path}

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File'
        }
    }
}

Function Remove-VideoFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Remove-VideoDatabaseItem -TableName 'File' -Id $Id
    }
}
#endregion

#region Video management
Function Test-Video {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $FileId
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
        Write-Verbose ('[{0}] Testing for video with file ID {1}' -f $MyInvocation.MyCommand, $FileId)
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Video' | ForEach-Object {
            if ($_.FileId -eq $FileId) {
                $Result = $true
            }
        }
        Write-Verbose ('[{0}] Result={1}' -f $MyInvocation.MyCommand, $Result)
        $Result
    }
}

Function New-Video {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $FileId
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $NextId = -1
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
        if (Test-Video -FileId $FileId) {
            throw ('[{0}] Video for file with id {1} already exists' -f $MyInvocation.MyCommand, $FileId)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Video' -Data @{
            FileId = $FileId
            NextId = $NextId
        }
    }
}

Function Get-Video {
    [CmdletBinding(DefaultParameterSetName='GetAll')]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByFileId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $FileId
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Write-Verbose ('[{0}] Retrieving video by ID ({1})' -f $MyInvocation.MyCommand, $Id)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Video' -Id $Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByFileId') {
            Write-Verbose ('[{0}] Retrieving video by file ID ({1})' -f $MyInvocation.MyCommand, $FileId)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Video' | Where-Object {$_.FileId -eq $FileId}

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Write-Verbose ('[{0}] Retrieving all videos' -f $MyInvocation.MyCommand)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Video'
        }
    }
}

Function Set-Video {
    [CmdletBinding(DefaultParameterSetName='SetNextId')]
    Param(
        [Parameter(ParameterSetName='SetFileId', Mandatory)]
        [Parameter(ParameterSetName='SetNextId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='SetFileId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $FileId
        ,
        [Parameter(ParameterSetName='SetNextId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $NextId
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
        $Video = Get-Video -Id $Id
        if ($PSCmdlet.ParameterSetName -ieq 'SetFileId') {
            $Video.FileId = $FileId

        } elseif ($PSCmdlet.ParameterSetName -ieq 'SetNextId') {
            $Video.NextId = $NextId
            Remove-Video -FileId $NextId
        }
    }
}

Function Remove-Video {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $FileId
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
        Write-Verbose ('[{0}] Removing video with file ID {1}' -f $MyInvocation.MyCommand, $FileId)
        $Video = Get-Video -FileId $FileId
        Write-Verbose ('[{0}] Removing video with ID {1}' -f $MyInvocation.MyCommand, $Video.Id)
        Remove-VideoDatabaseItem -TableName 'Video' -Id $Video.Id
    }
}
#endregion

#region Tag management
Function Test-Tag {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag' | ForEach-Object {
            if ($_.Name -ieq $Name) {
                $Result = $true
            }
        }

        $Result
    }
}

Function New-Tag {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Tag -Name $Name) {
            throw ('[{0}] Tag "{1}" already exists' -f $MyInvocation.MyCommand, $Name)
        }

        Write-Verbose ('[{0}] Creating new tag called {1}' -f $MyInvocation.MyCommand, $Name)
        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag' -Data @{
            Name = $Name
        }
    }
}

Function Get-Tag {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag' -Id $Id
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByName') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag' | Where-Object {$_.Name -ieq $Name}
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag'
        }
    }
}

Function Set-Tag {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Tag -Name $Name) {
            throw ('[{0}] Tag "{1}" already exists' -f $MyInvocation.MyCommand, $Name)
        }

        $Tag = Get-Tag -Id $Id
        $Tag.Name = $Name
    }
}

Function Remove-Tag {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Remove-VideoDatabaseItem -TableName 'Tag' -Id $Id
    }
}
#endregion

#region Tag assignment
Function Test-VideoTag {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $TagId
        ,
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TagName
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
        if ($PSCmdlet.ParameterSetName -ieq 'TagByName') {
            $TagId = (Get-Tag -Name $TagName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'TagById') {
            $TagName = (Get-Tag -Id $TagId).Name
        }

        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'TagToVideo' | ForEach-Object {
            if ($_.VideoId -eq $VideoId -and $_.TagId -eq $TagId) {
                $Result = $true
            }
        }

        $Result
    }
}

Function Add-VideoTag {
    [CmdletBinding(DefaultParameterSetName='TagByName')]
    Param(
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $TagId
        ,
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TagName
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
        if ($PSCmdlet.ParameterSetName -ieq 'TagByName') {
            $TagId = (Get-Tag -Name $TagName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'TagById') {
            $TagName = (Get-Tag -Id $TagId).Name
        }

        if (Test-VideoTag @PSBoundParameters) {
            throw ('[{0}] Tag {1} (id={2}) is already assigned to video (id={3})' -f $MyInvocation.MyCommand, $TagName, $TagId, $VideoId)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'TagToVideo' -Data @{
            VideoId = $VideoId
            TagId = $TagId
        }
    }
}

Function Get-VideoTag {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $TagId
        ,
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TagName
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
        if ($PSCmdlet.ParameterSetName -ieq 'TagByName') {
            $TagId = (Get-Tag -Name $TagName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'TagById') {
            $TagName = (Get-Tag -Id $TagId).Name
        }

        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'TagToVideo' | Where-Object {$_.VideoId -eq $VideoId -and $_.TagId -eq $TagId}
    }
}

Function Remove-VideoTag {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='TagById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $TagId
        ,
        [Parameter(ParameterSetName='TagByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TagName
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
        if ($PSCmdlet.ParameterSetName -ieq 'TagByName') {
            $TagId = (Get-Tag -Name $TagName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'TagById') {
            $TagName = (Get-Tag -Id $TagId).Name
        }

        $VideoTag = Get-VideoTag -VideoId $VideoId -TagId $TagId
        Remove-CliXmlDatabaseItem -Connection 'VideoDatabase' -Table 'TagToVideo' -Id $VideoTag.Id
    }
}
#endregion

#region Person management
Function Test-Person {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person' | ForEach-Object {
            if ($_.Name -ieq $Name) {
                $Result = $true
            }
        }

        $Result
    }
}

Function New-Person {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Person -Name $Name) {
            throw ('[{0}] Person "{1}" already exists' -f $MyInvocation.MyCommand, $Name)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person' -Data @{
            Name = $Name
        }
    }
}

Function Get-Person {
    [CmdletBinding(DefaultParameterSetName='GetAll')]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person' -Id $Id
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByName') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person' | Where-Object {$_.Name -ieq $Name}
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person'
        }
    }
}

Function Set-Person {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Person -Name $Name) {
            throw ('[{0}] Person "{1}" does not exist' -f $MyInvocation.MyCommand, $Name)
        }

        $Person = Get-Person -Id $Id
        $Person.Name = $Name
    }
}

Function Remove-Person {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Remove-VideoDatabaseItem -TableName 'Person' -Id $Id
    }
}
#endregion

#region Person assignment
Function Test-VideoPerson {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PersonId
        ,
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PersonName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PersonByName') {
            $PersonId = (Get-Person -Name $PersonName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PersonById') {
            $PersonName = (Get-Person -Id $PersonId).Name
        }

        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo' | ForEach-Object {
            if ($_.VideoId -eq $VideoId -and $_.PersonId -eq $PersonId) {
                $Result = $true
            }
        }

        $Result
    }
}

Function Add-VideoPerson {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PersonId
        ,
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PersonName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PersonByName') {
            $PersonId = (Get-Person -Name $PersonName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PersonById') {
            $PersonName = (Get-Person -Id $PersonId).Name
        }

        if (Test-VideoPerson @PSBoundParameters) {
            throw ('[{0}] Person {1} (id={2}) is already assigned to video (id={3})' -f $MyInvocation.MyCommand, $PersonName, $PersonId, $VideoId)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo' -Data @{
            VideoId = $VideoId
            PersonId = $PersonId
        }
    }
}

Function Get-VideoPerson {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PersonId
        ,
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PersonName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PersonByName') {
            $PersonId = (Get-Person -Name $PersonName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PersonById') {
            $PersonName = (Get-Person -Id $PersonId).Name
        }

        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo' | Where-Object {$_.VideoId -eq $VideoId -and $_.PersonId -eq $PersonId}
    }
}

Function Remove-VideoPerson {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PersonById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PersonId
        ,
        [Parameter(ParameterSetName='PersonByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PersonName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PersonByName') {
            $PersonId = (Get-Person -Name $PersonName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PersonById') {
            $PersonName = (Get-Person -Id $PersonId).Name
        }

        $VideoPerson = Get-VideoPerson -VideoId $VideoId -PersonId $PersonId
        Remove-CliXmlDatabaseItem -Connection 'VideoDatabase' -Table 'PersonToVideo' -Id $VideoPerson.Id
    }
}
#endregion

#region Playlist management
Function Test-Playlist {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist' | ForEach-Object {
            if ($_.Name -ieq $Name) {
                $Result = $true
            }
        }

        $Result
    }
}

Function New-Playlist {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Playlist -Name $Name) {
            throw ('[{0}] Playlist "{1}" already exists' -f $MyInvocation.MyCommand, $Name)
        }

        Write-Verbose ('[{0}] Creating new playlist called {1}' -f $MyInvocation.MyCommand, $Name)
        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist' -Data @{
            Name = $Name
        }
    }
}

Function Get-Playlist {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist' -Id $Id
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByName') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist' | Where-Object {$_.Name -ieq $Name}
            
        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist'
        }
    }
}

Function Set-Playlist {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
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
        if (Test-Playlist -Name $Name) {
            throw ('[{0}] Playlist "{1}" already exists' -f $MyInvocation.MyCommand, $Name)
        }

        $Playlist = Get-Playlist -Id $Id
        $Playlist.Name = $Name
    }
}

Function Remove-Playlist {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Remove-VideoDatabaseItem -TableName 'Playlist' -Id $Id
    }
}
#endregion

#region Playlist item management
Function Test-PlaylistItem {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PlaylistId
        ,
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PlaylistName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PlaylistByName') {
            $PlaylistId = (Get-Playlist -Name $PlaylistName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PlaylistById') {
            $PlaylistName = (Get-Playlist -Id $PlaylistId).Name
        }

        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist' | ForEach-Object {
            if ($_.VideoId -eq $VideoId -and $_.PlaylistId -eq $PlaylistId) {
                $Result = $true
            }
        }

        $Result
    }
}

Function Add-PlaylistItem {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PlaylistId
        ,
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PlaylistName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PlaylistByName') {
            $PlaylistId = (Get-Playlist -Name $PlaylistName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PlaylistById') {
            $PlaylistName = (Get-Playlist -Id $PlaylistId).Name
        }

        if (Test-PlaylistItem @PSBoundParameters) {
            throw ('[{0}] Playlist {1} (id={2}) is already assigned to video (id={3})' -f $MyInvocation.MyCommand, $PlaylistName, $PlaylistId, $VideoId)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist' -Data @{
            VideoId = $VideoId
            PlaylistId = $PlaylistId
        }
    }
}

Function Get-PlaylistItem {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PlaylistId
        ,
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PlaylistName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PlaylistByName') {
            $PlaylistId = (Get-Playlist -Name $PlaylistName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PlaylistById') {
            $PlaylistName = (Get-Playlist -Id $PlaylistId).Name
        }

        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist' | Where-Object {$_.VideoId -eq $VideoId -and $_.PlaylistId -eq $PlaylistId}
    }
}

Function Remove-PlaylistItem {
    [CmdletBinding()]
    Param(
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='PlaylistById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $PlaylistId
        ,
        [Parameter(ParameterSetName='PlaylistByName', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $PlaylistName
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
        if ($PSCmdlet.ParameterSetName -ieq 'PlaylistByName') {
            $PlaylistId = (Get-Playlist -Name $PlaylistName).Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'PlaylistById') {
            $PlaylistName = (Get-Playlist -Id $PlaylistId).Name
        }

        $PlaylistItem = Get-PlaylistItem -VideoId $VideoId -PlaylistId $PlaylistId
        Remove-CliXmlDatabaseItem -Connection 'VideoDatabase' -Table 'VideoToPlaylist' -Id $PlaylistItem.Id
    }
}
#endregion

#region Bookmark management
Function Test-Bookmark {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Timestamp
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
        Write-Verbose ('[{0}] Testing for bookmark with file ID {1} and timestamp {2}' -f $MyInvocation.MyCommand, $VideoId, $Timestamp)
        $Result = $false
        Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Bookmark' | ForEach-Object {
            if ($_.VideoId -eq $VideoId -and $_.Timestamp -eq $Timestamp) {
                $Result = $true
            }
        }
        Write-Verbose ('[{0}] Result={1}' -f $MyInvocation.MyCommand, $Result)
        $Result
    }
}

Function New-Bookmark {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Timestamp
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
        if (Test-Bookmark -VideoId $VideoId -Timestamp $Timestamp) {
            throw ('[{0}] Bookmark for video with id {1} and timestamp {2} already exists' -f $MyInvocation.MyCommand, $VideoId, $Timestamp)
        }

        New-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Bookmark' -Data @{
            VideoId   = $VideoId
            Timestamp = $Timestamp
        }
    }
}

Function Get-Bookmark {
    [CmdletBinding(DefaultParameterSetName='GetAll')]
    Param(
        [Parameter(ParameterSetName='GetById', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Id
        ,
        [Parameter(ParameterSetName='GetByVideoId', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $VideoId
        ,
        [Parameter(ParameterSetName='GetAll', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $All
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
        if ($PSCmdlet.ParameterSetName -ieq 'GetById') {
            Write-Verbose ('[{0}] Retrieving video by ID ({1})' -f $MyInvocation.MyCommand, $Id)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Bookmark' -Id $Id

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetByVideoId') {
            Write-Verbose ('[{0}] Retrieving video by file ID ({1})' -f $MyInvocation.MyCommand, $VideoId)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Bookmark' | Where-Object {$_.VideoId -eq $VideoId}

        } elseif ($PSCmdlet.ParameterSetName -ieq 'GetAll') {
            Write-Verbose ('[{0}] Retrieving all videos' -f $MyInvocation.MyCommand)
            Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Bookmark'
        }
    }
}

Function Remove-Bookmark {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
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
        Write-Verbose ('[{0}] Removing bookmark with ID {1}' -f $MyInvocation.MyCommand, $Id)
        
        $Bookmark = Get-Bookmark -Id $Id
        Remove-BookmarkDatabaseItem -TableName 'Bookmark' -Id $Bookmark.Id
    }
}
#endregion