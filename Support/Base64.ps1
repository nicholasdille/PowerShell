function ConvertTo-Base64 {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Data
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Data
    )

    BEGIN {
        Write-Verbose ('[{0}] Converting to Base64 encoding' -f $MyInvocation.MyCommand)
        $MultiLineData = @()
    }

    PROCESS {
        Write-Debug ('[{0}] Adding next line to input array' -f $MyInvocation.MyCommand)
        $MultiLineData += @($Data)
    }

    END {
        Write-Debug ('[{0}] Joining input array using \r\n' -f $MyInvocation.MyCommand)
        $RawData = $MultiLineData -join "`r`n"

        $ByteData = [system.Text.Encoding]::Unicode.GetBytes($RawData)
        Write-Debug ('[{0}] Obtained byte data of type <{1}>' -f $MyInvocation.MyCommand, $ByteData.GetType().BaseType)

        $Base64Data = [System.Convert]::ToBase64String($ByteData)
        Write-Debug ('[{0}] Obtained Base64 encoded data of type <{1}>' -f $MyInvocation.MyCommand, $Base64Data.GetType().BaseType)

        Write-Verbose ('[{0}] Done and returning Base64 encoded data' -f $MyInvocation.MyCommand)
        return $Base64Data
    }
}

function ConvertFrom-Base64 {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Data
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Data
    )

    Write-Verbose ('[{0}] Converting from Base64 encoding' -f $MyInvocation.MyCommand)

    $ByteData = [System.Convert]::FromBase64String($Data)
    Write-Debug ('[{0}] Obtained byte data of type <{1}>' -f $MyInvocation.MyCommand, $ByteData.GetType().BaseType)
    
    $RawData = [System.Text.Encoding]::Unicode.GetString($ByteData)
    Write-Debug ('[{0}] Obtained data with original encoding of type <{1}>' -f $MyInvocation.MyCommand, $RawData.GetType().BaseType)

    Write-Verbose ('[{0}] Done and returning data' -f $MyInvocation.MyCommand)
    $RawData
}

function ConvertTo-UnattendXmlPassword {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Password
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Password
    )

    return ConvertTo-Base64 -Data $Password
}

function ConvertFrom-UnattendXmlPassword {
    <#
    .SYNOPSIS
    XXX

    .DESCRIPTION
    XXX

    .PARAMETER Password
    XXX

    .EXAMPLE
    XXX
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Password
    )

    return ConvertFrom-Base64 -Data $Password
}