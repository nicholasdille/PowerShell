$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')
#. "$here\$sut"

#Import-Module "$PSScriptRoot\..\Support"
. "$PSScriptRoot\..\Support\$sut"

Describe 'Remoting' {
    Context 'Convert-RemoteFilePath' {
    }
    Context 'Copy-VMFileRemotely' {
    }
    Context 'Copy-ToRemoteItem' {
    }
    Context 'Copy-FromRemoteItem' {
    }
    Context 'Import-RemoteModule' {
    }
}