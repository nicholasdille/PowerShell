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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [Parameter(Mandatory=$false)]
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