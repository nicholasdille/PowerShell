﻿function Split-BinaryFile {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [int]
        $Size
    )

    Process{
        $ChunkIndex = 0
        Get-Content -ReadCount $Size -Encoding Byte -Path $Path | ForEach-Object {
            $ChunkExtension = '0' * (3 - $ChunkIndex.ToString().Length)
            $ChunkPath = "$Path.$ChunkExtension$ChunkIndex"

            Write-Verbose -Message ('Processing chunk {0}' -f $ChunkIndex)
            Set-Content -Encoding Byte -Path $ChunkPath -Value $_
            $ChunkPath

            ++$ChunkIndex
        }
    }
}

function Join-BinaryFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationPath
        ,
        [switch]
        $Force
    )

    Process{
        if (Test-Path -Path $DestinationPath) {
            if ($Force) {
                Remove-Item -Path $DestinationPath -Force

            } else {
                Write-Error -Message ('Destination path {0} already exists. Aborting.' -f $DestinationPath)
            }
        }

        $Path | ForEach-Object {
            Get-Content -Path $_ -Encoding Byte | Add-Content -Path $DestinationPath -Encoding Byte
        }
    }
}

function New-FileHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
        ,
        [Parameter()]
        [string]
        $Algorithm = 'SHA256'
    )

    Process {
        $Path | ForEach-Object {
            Get-FileHash -Path $_ -Algorithm $Algorithm | Select-Object -ExpandProperty Hash | Set-Content -Path "$_.$Algorithm"
        }
    }
}

function Test-FileHash {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReferencePath
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DifferencePath
    )

    Process {
        return ((Compare-Object -ReferenceObject (Get-Content -Path $ReferencePath) -DifferenceObject (Get-Content -Path $DifferencePath)).Count -eq 0)
    }
}

function Compare-FileHash {
    [cmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ReferencePath
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DifferencePath
        ,
        [switch]
        $ShowMatchesOnly
        ,
        [Parameter()]
        [string]
        $Algorithm = 'SHA256'
    )

    Process {
        if ((Compare-Object -ReferenceObject (Get-ChildItem -Path $DifferencePath -File | Select-Object -Property Name,Length) -DifferenceObject (Get-ChildItem -Path $ReferencePath -File | Select-Object -Property Name,Length)).Count -eq 0) {
            Get-ChildItem -Path $DifferencePath -File -Filter '*.SHA256' | ForEach-Object {
                Write-Verbose -Message ('Processing {0}' -f $_.Name)
                if (Test-FileHash -ReferencePath "$ReferencePath\$($_.Name)" -DifferencePath "$DifferencePath\$($_.Name)") {
                    if ($ShowMatchesOnly) {
                        "$ReferencePath\$($_.BaseName)"
                    }

                } else {
                    if (-not $ShowMatchesOnly) {
                        "$ReferencePath\$($_.BaseName)"
                    }
                }
            }

        } else {
            Get-ChildItem -Path $DifferencePath -File -Filter '*.SHA256' | ForEach-Object {"$($_.Directory)\$($_.BaseName)"}
        }
    }
}

function Set-TemporaryFileAttribute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    Process {
        foreach ($FilePath in $Path) {
            $File = Get-Item -Path $FilePath
            $File.Attributes = $File.Attributes -bor 0x100
        }
    }
}

function Clear-TemporaryFileAttribute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [Alias('FullName')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path
    )

    Process {
        foreach ($FilePath in $Path) {
            $File = Get-Item -Path $FilePath
            $File.Attributes = $File.Attributes -band 0xfeff
        }
    }
}