function Find-DuplicateItem {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Path
    XXX

    .PARAMETER DestinationPath
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
    )

    if (-Not (Test-Path -Path $Path)) {
        throw ('[{0}] Source path <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }
    if (-Not (Test-Path -Path $DestinationPath)) {
        throw ('[{0}] Destination path <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $DestinationPath)
    }

    $DestinationFiles = @{}
    Get-ChildItem -Path $DestinationPath -Recurse | ForEach-Object {
        if (-Not $DestinationFiles.ContainsKey($_.Name)) {
            $DestinationFiles.Add($_.Name, $_)

        } else {
            Write-Warning ('[{0}] Destination item <{1}> may be a duplicate for <{2}>. Ignoring.' -f $MyInvocation.MyCommand, $_.FullName, $DestinationFiles[$_.Name].FullName)
        }
    }
    Write-Verbose ('[{0}] Read {1} items from destination path <{2}>' -f $MyInvocation.MyCommand, $DestinationFiles.Count, $Path)

    Get-ChildItem -Path $Path | ForEach-Object {
        if (-Not $DestinationFiles.ContainsKey($_.Name)) {
            Write-Verbose ('[{0}] New item <{1}> found' -f $MyInvocation.MyCommand, $_.Name)

        } else {
            $_
        }
    }
}

function Move-DuplicateItem {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Path
    XXX

    .PARAMETER DestinationPath
    XXX

    .PARAMETER DuplicatePath
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]
        $DuplicatePath = 'Duplicates'
    )

    if (-Not (Test-Path -Path $DuplicatePath)) {
        Write-Verbose ('[{0}] Path for duplicate items <{1}> does not exist. Appending to source path.' -f $MyInvocation.MyCommand, $DuplicatePath)
        $DuplicatePath = Join-Path -Path $Path -ChildPath $DuplicatePath
    }
    if (-Not (Test-Path -Path $DuplicatePath)) {
        throw ('[{0}] Path for dupliate items <{1}> does not exist. Aborting.' -f $MyInvocation.MyCommand, $DuplicatePath)
    }

    Find-DuplicateItem -Path $Path -DestinationPath $DestinationPath | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $DuplicatePath
    }
}

function Get-FolderSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    PROCESS {
        foreach ($Item in $Path) {
            Write-Verbose ('[{0}] Processing folder <{1}>' -f $MyInvocation.MyCommand, $Item)
            $stats = Get-ChildItem -Path $Item -File -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Length | Measure-Object -Sum
            [PSCustomObject]@{
                Path  = $Item
                Size  = $stats.Sum
                Count = $stats.Count
            }
        }
    }
}

function Get-Tree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw ('[{0}] Specified path ({1}) does not exist. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }
    if (-not (Get-Item -Path $Path | Select-Object -ExpandProperty PSIsContainer)) {
        throw ('[{0}] Specified path ({1}) is not a container. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }
    
    Get-Item -Path $Path | Select-Object -ExpandProperty FullName
    Get-ChildItem -Path $Path -Recurse -Directory | Select-Object -ExpandProperty FullName
}

function Get-FileExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw ('[{0}] Specified path ({1}) does not exist. Aborting.' -f $MyInvocation.MyCommand, $Path)
    }

    Get-ChildItem -Path $Path -File -Recurse | Select -ExpandProperty Extension | Group-Object | Select-Object Name,Count | Sort-Object -Property Count -Descending
}

function Get-DuplicateItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
    )

    $Files = Get-ChildItem -Path $Path -Recurse -File
    $Duplicates = $Files | Group-Object -Property Length | Where-Object { $_.Count -gt 1 }

    $Duplicates | ForEach-Object {
        #Write-Host "Name: $($_.Name) | Count: $($_.Count)"

        Foreach ($item in $_.Group) {
            #Write-Host "    $($item.FullName)"
            $item
        }
    }
}