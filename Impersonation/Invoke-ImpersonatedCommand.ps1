param( [ScriptBlock] $scriptBlock )
<#
    .SYNOPSIS 
          Impersonates a user and executes a script block as that user. This is an interactive script
        and a window will open in order to securely capture credentials.
    .EXAMPLE
        Use-Impersonation.ps1 {Get-ChildItem 'C:\' | Foreach { Write-Host $_.Name }}
        This writes the contents of 'C:\' impersonating the user that is entered.
#>
    
$logonUserSignature =
@'
[DllImport( "advapi32.dll" )]
public static extern bool LogonUser( String lpszUserName,
                                     String lpszDomain,
                                     IntPtr lpszPassword,
                                     int dwLogonType,
                                     int dwLogonProvider,
                                     ref IntPtr phToken );
'@
 
$AdvApi32 = Add-Type -MemberDefinition $logonUserSignature -Name 'AdvApi32' -Namespace 'PsInvoke.NativeMethods' -PassThru
 
$closeHandleSignature =
@'
[DllImport( "kernel32.dll", CharSet = CharSet.Auto )]
public static extern bool CloseHandle( IntPtr handle );
'@
 
$Kernel32 = Add-Type -MemberDefinition $closeHandleSignature -Name 'Kernel32' -Namespace 'PsInvoke.NativeMethods' -PassThru
    
$credentials = Get-Credential
 
try
{
    $Logon32ProviderDefault = 0
    $Logon32LogonInteractive = 2
    $Logon32LogonNetwork = 3
    $Logon32LogonBatch = 4
    $Logon32LogonService = 5
    $Logon32LogonUnlock = 7
    $Logon32LogonNetworkCleartext = 8
    $Logon32LogonNewCredentials = 9
    $tokenHandle = [IntPtr]::Zero
    $userName = Split-Path $credentials.UserName -Leaf
    $domain = Split-Path $credentials.UserName
    $unmanagedString = [IntPtr]::Zero;
    $success = $false
    
    try
    {
        $unmanagedString = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($credentials.Password);
        $success = $AdvApi32::LogonUser($userName, $domain, $unmanagedString, $Logon32LogonNewCredentials, $Logon32ProviderDefault, [Ref] $tokenHandle)
    }
    finally
    {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($unmanagedString);
    }
    
    if (!$success )
    {
        $retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-Host "LogonUser was unsuccessful. Error code: $retVal"
        return
    }
 
    Write-Host 'LogonUser was successful.'
    Write-Host "Value of Windows NT token: $tokenHandle"
 
    $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "Current Identity: $identityName"
 
    $newIdentity = New-Object System.Security.Principal.WindowsIdentity( $tokenHandle )
    $context = $newIdentity.Impersonate()
 
    $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "Impersonating: $identityName"
 
    Write-Host 'Executing custom script'
    & $scriptBlock
}
catch [System.Exception]
{
    Write-Host $_.Exception.ToString()
}
finally
{
    if ( $context -ne $null )
    {
        $context.Undo()
    }
    if ( $tokenHandle -ne [System.IntPtr]::Zero )
    {
        $Kernel32::CloseHandle( $tokenHandle )
    }
}