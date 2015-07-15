function ConvertTo-EncryptedString {
    <#
    .SYNOPSIS
    Encrypts the contents of a secure string to make it usable on another system

    .DESCRIPTION
    A SecureString cannot be used on a different system than the one it was created on. This function encrypts the password using a custom encryption key to make the contents portable

    .PARAMETER SecureString
    Sensitive content

    .PARAMETER Key
    Custom encryption key

    .EXAMPLE
    ConvertTo-EncryptedString -SecureString $SecureString -Key 'key012345678'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]
        $SecureString
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key
    )

    $ByteData = [System.Text.Encoding]::ASCII.GetBytes($Key)
    ConvertFrom-SecureString -SecureString $SecureString -Key $ByteData
}

function ConvertFrom-EncryptedString {
    <#
    .SYNOPSIS
    Decrypts a string to a secure string to use it for credentials on the current system

    .DESCRIPTION
    Many cmdlets for handling credentials rely on a SecureString. This function decrypts the sensitive data and converts it to a SecureString

    .PARAMETER EncryptedString
    Encrypted content

    .PARAMETER Key
    Custom encryption key

    .EXAMPLE
    ConvertFrom-EncryptedString -EncryptedString $SecureString -Key 'key012345678'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]
        $EncryptedString
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Key
    )

    $ByteData = [System.Text.Encoding]::ASCII.GetBytes($Key)
    ConvertTo-SecureString -String $EncryptedString -Key $ByteData
}

function Get-PlaintextFromSecureString {
    <#
    .SYNOPSIS
    Extract the plaintext content from a SecureString

    .PARAMETER SecureString
    Sensitive content

    .EXAMPLE
    Get-PlaintextFromSecureString -SecureString $Password
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory,ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Security.SecureString]
        $SecureString
    )

    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

Function New-Password() {
    <#
    .SYNOPSIS
    Generates a new password

    .DESCRIPTION
    The password is based on an alphabet

    .PARAMETER Length
    Length of the password

    .PARAMETER Alphabet
    Alphabet used for generating the password

    .EXAMPLE
    New-Password -Length 12

    .EXAMPLE
    New-Password -Length 12 -Alphabet "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".ToCharArray()
    #>
    [CmdletBinding()]
    [OutputType([string])]
    Param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [int]
        $Length=10
        ,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Alphabet
    )

    if (-Not $Alphabet) {
        $Alphabet = $null
        40..126 + 33 + 35..38 | ForEach-Object {
            $Alphabet += ,[char][byte]$_
        }
    }

    $TempPassword = ''
    For ($i = 1; $i –le $Length; $i++) {
        $TempPassword += ($Alphabet | Get-Random)
    }

    return $TempPassword
}