#Requires -Version 4
Set-StrictMode -Version 4

<#if (-not (Get-Module -Name PSScriptAnalyzer -ErrorAction SilentlyContinue)) {
    Invoke-ScriptAnalyzer -Path "$PSScriptRoot\CliXmlDatabase.psm1" -ExcludeRule PSProvideDefaultParameterValue
}#>

Import-Module -Name "$PSScriptRoot\..\CliXmlDatabase" -Force

$ConfirmPreference = 'None'

Describe 'Unit tests for CliXml based database' {
    InModuleScope CliXmlDatabase {
        Context 'New-CliXmlDatabase' {
            It 'Creates the directory for a new database' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Test-Path -Path TestDrive:\Test | Should Be $true
            }
            It 'Throws if directory for new database already exists' {
                { New-CliXmlDatabase -Path TestDrive:\Test } | Should Throw
                Remove-Item -Path TestDrive:\Test -Recurse -Force
            }
        }
        Context 'Test-CliXmlDatabase' {
            It 'Succeeds if database exists' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Test-CliXmlDatabase -Path TestDrive:\Test | Should Be $true
                Remove-Item -Path TestDrive:\Test -Recurse -Force
            }
            It 'Fails if database does not exist' {
                Test-CliXmlDatabase -Path TestDrive:\Test | Should Be $false
            }
        }
        Context 'Assert-CliXmlDatabase' {
            It 'Succeeds if database exists' {
                New-CliXmlDatabase -Path TestDrive:\Test
                { Assert-CliXmlDatabase -Path TestDrive:\Test } | Should Not Throw
                Remove-Item -Path TestDrive:\Test -Recurse -Force
            }
            It 'Throws if database does not exist' {
                { Assert-CliXmlDatabase -Path TestDrive:\Test } | Should Throw
            }
        }
        Context 'Open-CliXmlDatabase' {
            New-CliXmlDatabase -Path TestDrive:\Test
            It 'Creates a connection object' {
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                $Connection = $Connections | Where-Object {$_.Name -ieq 'Pester'}
                $Connection.Keys -icontains 'Name' | Should Be $true
                $Connection.Keys -icontains 'Path' | Should Be $true
                $Connection.Keys -icontains 'Data' | Should Be $true
                $Connection.Name | Should Be 'Pester'
                $Connection.Path | Should Be TestDrive:\Test
                Close-CliXmlDatabase -ConnectionName 'Pester'
            }
            It 'Throws if a connection name is already in use' {
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                { Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test } | Should Throw
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Remove-CliXmlDatabase -Path TestDrive:\Test
            }
            It 'Correctly imports data' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test')
                $Data.Count | Should Be 1
                $Data[0].Name | Should Be 'TestName'
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Close-CliXmlDatabase' {
            It 'Throws if the connection does not exist' {
                { Close-CliXmlDatabase -ConnectionName 'DoesNotExist' } | Should Throw
            }
            It 'Exports data to CliXml' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Test-Path -Path TestDrive:\Test\Test.clixml| Should Be $true
                $Data = @(Import-Clixml -Path TestDrive:\Test\Test.clixml)
                $Data.Count | Should Be 1
                $Data[0].Name | Should Be 'TestName'
                Remove-CliXmlDatabase -Path TestDrive:\Test
            }
            It 'Can import exported data ' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                $Item = Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0
                $Item.Name | Should Be 'TestName'
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
            It 'Removed connection data' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Test-CliXmlDatabaseConnection -ConnectionName 'Pester' | Should Be $false
                Remove-CliXmlDatabase -Path TestDrive:\Test
            }
        }
        Context 'Remove-CliXmlDatabase' {
            New-CliXmlDatabase -Path TestDrive:\Test
            It 'Throws if database at specified path is open' {
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                { Remove-CliXmlDatabase -Path TestDrive:\Test } | Should Throw
                Close-CliXmlDatabase -ConnectionName 'Pester'
            }
            It 'Removes database' {
                Remove-CliXmlDatabase -Path TestDrive:\Test
                Test-CliXmlDatabase -Path TestDrive:\Test | Should Be $false
            }
        }
        Context 'Get-CliXmlDatabaseConnection' {
            It 'Returns existing connection' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                $Connection = Get-CliXmlDatabaseConnection -ConnectionName 'Pester'
                $Connection | Should Not Be Null
                $Connection.Name | Should Be 'Pester'
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Remove-CliXmlDatabase -Path TestDrive:\Test
            }
            It 'Empty output if connection does not exist' {
                $Connection = Get-CliXmlDatabaseConnection -ConnectionName 'Pester'
                $Connection | Should Be $null
            }
        }
        Context 'Test-CliXmlDatabaseConnection' {
            It 'Throws if database connection does not exist' {
                Test-CliXmlDatabaseConnection -ConnectionName 'Pester' | Should Be $false
            }
            It 'Succeeds if database connection exists' {
                New-CliXmlDatabase -Path TestDrive:\Test
                Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
                Test-CliXmlDatabaseConnection -ConnectionName 'Pester' | Should Be $true
                Close-CliXmlDatabase -ConnectionName 'Pester'
                Remove-CliXmlDatabase -Path TestDrive:\Test
            }
        }
        Context 'Assert-CliXmlDatabaseConnection' {
            It 'Throws if database connection does not exist' {
                { Assert-CliXmlDatabaseConnection -ConnectionName 'Pester' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Succeeds if database connection exists' {
                { Assert-CliXmlDatabaseConnection -ConnectionName 'Pester' } | Should Not Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'New-CliXmlDatabaseTable' {
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Adds a new table' {
                New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                $Path = 'TestDrive:\Test\Test.clixml'
                Test-Path -Path $Path | Should Be $true
            }
            It 'Throws if the new table already exists' {
                New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test2'
                { New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test2' } | Should Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Test-CliXmlDatabaseTable' {
            It 'Throws if the connection does not exist' {
                { Test-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Fails if database table does not exist' {
                Test-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' | Should Be $false
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Succeeds if database table exists' {
                Test-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' | Should Be $true
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Assert-CliXmlDatabaseTable' {
            It 'Throws if the connection does not exist' {
                { Assert-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Fails if database table does not exist' {
                { Assert-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Succeeds if database table exists' {
                { Assert-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Not Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Get-CliXmlDatabaseTable' {
            It 'Throws if the connection does not exist' {
                { Get-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Get-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            It 'Returns nothing on empty database' {
                $Tables = @(Get-CliXmlDatabaseTable -ConnectionName 'Pester')
                $Tables.Count | Should Be 0
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test1'
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test2'
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test3'
            It 'Returns tables' {
                $Tables = @(Get-CliXmlDatabaseTable -ConnectionName 'Pester')
                $Tables.Count | Should Be 3
                $Tables -contains 'Test1' | Should Be $true
                $Tables -contains 'Test2' | Should Be $true
                $Tables -contains 'Test3' | Should Be $true
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Clear-CliXmlDatabaseTable' {
            It 'Throws if the connection does not exist' {
                { Clear-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Clear-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'} | Out-Null
            It 'Clears the table' {
                Clear-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test')
                $Data.Count | Should Be 0
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Remove-CliXmlDatabaseTable' {
            It 'Throws if the connection does not exist' {
                { Remove-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Remove-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Removes existing table' {
                Remove-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                $Tables = @(Get-CliXmlDatabaseTable -ConnectionName 'Pester')
                $Tables.Count | Should Be 0
            }
            It 'Throws if table does not exist' {
                { Remove-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Get-CliXmlDatabaseTableKey' {
            It 'Throws if the connection does not exist' {
                { Get-CliXmlDatabaseTableKey -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Get-CliXmlDatabaseTableKey -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Returns a new key for an empty table' {
                $Key = Get-CliXmlDatabaseTableKey -ConnectionName 'Pester' -TableName 'Test'
                $Key | Should Be 0
            }
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
            It 'Returns a new key for a filled table' {
                $Key = Get-CliXmlDatabaseTableKey -ConnectionName 'Pester' -TableName 'Test'
                $Key | Should Be 1
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Assert-CliXmlDatabaseTableField' {
            It 'Throws if the connection does not exist' {
                { Assert-CliXmlDatabaseTableField -ConnectionName 'Pester' -TableName 'Test' -Key @('Name') } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Assert-CliXmlDatabaseTableField -ConnectionName 'Pester' -TableName 'Test' -Key @('Name') } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Succeeds if table is empty' {
                { Assert-CliXmlDatabaseTableField -ConnectionName 'Pester' -TableName 'Test' -Key @('Name') } | Should Not Throw
            }
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
            It 'Succeeds if keys match' {
                { Assert-CliXmlDatabaseTableField -ConnectionName 'Pester' -TableName 'Test' -Key @('Name') } | Should Not Throw
            }
            It 'Throws if keys do not match' {
                { Assert-CliXmlDatabaseTableField -ConnectionName 'Pester' -TableName 'Test' -Key @('Name2') } | Should Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'New-CliXmlDatabaseItem' {
            It 'Throws if the connection does not exist' {
                { New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'} } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'} } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Adds a new item to a table' {
                New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
                $Connection = Get-CliXmlDatabaseConnection -ConnectionName 'Pester'
                $Item = @($Connection.Data['Test'].Values | Where-Object {$_.Name -ieq 'TestName'})
                $Item.Count | Should Be 1
                $Item[0].Name | Should Be 'TestName'
            }
            It 'Adds several items to a table' {
                {
                    New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName2'}
                    New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName3'}
                    New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName4'}
                } | Should Not Throw
            }
            It 'Throws if specified data is mangled' {
                { New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name2 = 'TestName2'} } | Should Throw
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Get-CliXmlDatabaseItem' {
            It 'Throws if the connection does not exist' {
                { Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Succeeds if table is empty' {
                Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0
            }
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName2'}
            It 'Returns an item by ID' {
                $Item = @(Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0)
                $Item.Count | Should Be 1
                $Item[0].Id | Should Be 0
                $Item[0].Name | Should Be 'TestName'
            }
            It 'Returns all items' {
                $Item = @(Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test')
                $Item.Count | Should Be 2
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Set-CliXmlDatabaseItem' {
            It 'Throws if the connection does not exist' {
                { Set-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0 -Data @{Name = 'TestName'} } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Set-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0 -Data @{Name = 'TestName'} } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            New-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Data @{Name = 'TestName'}
            It 'Throws if specified data is mangled' {
                { Set-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0 -Data @{Name2 = 'TestName2'} } | Should Throw
            }
            It 'Updates data' {
                Set-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0 -Data @{Name = 'UpdatedTestName'}
                $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0)
                $Data.Count | Should Be 1
                $Data[0].Name | Should Be 'UpdatedTestName'
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
        Context 'Remove-CliXmlDatabaseItem' {
            It 'Throws if the connection does not exist' {
                { Remove-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0 } | Should Throw
            }
            New-CliXmlDatabase -Path TestDrive:\Test
            Open-CliXmlDatabase -ConnectionName 'Pester' -Path TestDrive:\Test
            It 'Throws if the table does not exist' {
                { Remove-CliXmlDatabaseItem -ConnectionName 'Pester' -TableName 'Test' -Id 0  } | Should Throw
            }
            New-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
            It 'Removes a table' {
                Remove-CliXmlDatabaseTable -ConnectionName 'Pester' -TableName 'Test'
                $Tables = @(Get-CliXmlDatabaseTable -ConnectionName 'Pester')
                $Tables.Count | Should Be 0
            }
            Close-CliXmlDatabase -ConnectionName 'Pester'
            Remove-CliXmlDatabase -Path TestDrive:\Test
        }
    }
}