Import-Module -Name "$PSScriptRoot\..\..\PowerShell\CliXmlDatabase\CliXmlDatabase.psm1" -Force
Import-Module -Name "$PSScriptRoot\VideoDatabase.psm1" -Force

$ConfirmPreference = 'None'

Describe 'Unit tests for video database' {
    Context 'Database management' {
        It 'Creates a new database' {
            New-VideoDatabase -Path TestDrive:\VideoDatabase
            Test-Path -Path TestDrive:\VideoDatabase | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\Location.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\File.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\Video.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\Tag.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\TagToVideo.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\Person.clixml | Should Be $true
            Test-Path -Path TestDrive:\VideoDatabase\PersonToVideo.clixml | Should Be $true
        }
        It 'Opens a database' {
            Open-VideoDatabase -Path TestDrive:\VideoDatabase
            Test-CliXmlDatabaseConnection -ConnectionName 'VideoDatabase' | Should Be $true
        }
        It 'Closes a database' {
            Close-VideoDatabase
            Test-CliXmlDatabaseConnection -ConnectionName 'VideoDatabase' | Should Be $false
        }
    }
    New-VideoDatabase -Path TestDrive:\VideoDatabase
    Open-VideoDatabase -Path TestDrive:\VideoDatabase
    Context 'Location management' {
        It 'Creates a new video location' {
            New-VideoLocation -Name 'Pester' -Path TestDrive:\VideoLocation
            $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Location')
            $Data.Count | Should Be 1
            $Data[0].Name | Should Be 'Pester'
            $Data[0].Path | Should Be 'TestDrive:\VideoLocation'
        }
        It 'Retrieves all video locations' {
            $Data = @(Get-VideoLocation -All)
            $Data.Count | Should Be 1
            $Data[0].Name | Should Be 'Pester'
            $Data[0].Path | Should Be 'TestDrive:\VideoLocation'
        }
        It 'Retrieves the video location by name' {
            $Data = @(Get-VideoLocation -Name 'Pester')
            $Data.Count | Should Be 1
            $Data[0].Name | Should Be 'Pester'
            $Data[0].Path | Should Be 'TestDrive:\VideoLocation'
        }
        It 'Retrieves the video location path' {
            $Data = @(Get-VideoLocation -Path TestDrive:\VideoLocation)
            $Data.Count | Should Be 1
            $Data[0].Name | Should Be 'Pester'
            $Data[0].Path | Should Be 'TestDrive:\VideoLocation'
        }
        It 'Retrieves the video location by ID' {
            $Data = @(Get-VideoLocation -Id 0)
            $Data.Count | Should Be 1
            $Data[0].Name | Should Be 'Pester'
            $Data[0].Path | Should Be 'TestDrive:\VideoLocation'
        }
        It 'Tests for video location path' {
            Test-VideoLocation -Path TestDrive:\DoesNotExist | Should Be $false
            Test-VideoLocation -Path TestDrive:\VideoLocation | Should Be $true
        }
        It 'Adds a second location with the same name' {
            $Location = New-VideoLocation -Name 'Pester' -Path TestDrive:\VideoLocation
            @(Get-VideoLocation -All).Count | Should Be 1
        }
        It 'Find a video location' {
            Find-VideoLocation -Path TestDrive:\VideoLocation\Video.mp4 | Should Not Be $null
            Find-VideoLocation -Path TestDrive:\OtherLocation\Video.mp4 | Should Be $null
        }
        It 'Updates a video location (name)' {
            Set-VideoLocation -Id 0 -Name 'Pester2'
            (Get-VideoLocation -Id 0).Name | Should Be 'Pester2'
        }
        It 'Updates a video location (path)' {
            Set-VideoLocation -Id 0 -Path TestDrive:\VideoLocation2
            (Get-VideoLocation -Id 0).Path | Should Be TestDrive:\VideoLocation2
        }
        It 'Updates a video location (name and path)' {
            Set-VideoLocation -Id 0 -Name 'Pester' -Path TestDrive:\VideoLocation
            (Get-VideoLocation -Id 0).Name | Should Be 'Pester'
            (Get-VideoLocation -Id 0).Path | Should Be TestDrive:\VideoLocation
        }
        It 'Removes a video location' {
            Remove-VideoLocation -Id 0
            @(Get-VideoLocation -All).Count | Should Be 0
        }
    }
    Context 'File management' {
        New-VideoLocation -Name 'Pester' -Path TestDrive:\VideoLocation
        It 'Splits a path from the root directory' {
            $Data = Split-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
            $Data.Path | Should Be TestDrive:\VideoLocation\Video.mp4
            $Data.FileBaseName | Should Be 'Video'
            $Data.FileName | Should Be 'Video.mp4'
            $Data.FilePath | Should Be TestDrive:\VideoLocation\
            $Data.SubPath | Should Be '\'
        }
        It 'Splits a path from a subdirectory' {
            $Data = Split-VideoFile -Path TestDrive:\VideoLocation\SubDir\Video.mp4
            $Data.Path | Should Be TestDrive:\VideoLocation\SubDir\Video.mp4
            $Data.FileBaseName | Should Be 'Video'
            $Data.FileName | Should Be 'Video.mp4'
            $Data.FilePath | Should Be TestDrive:\VideoLocation\SubDir\
            $Data.SubPath | Should Be '\SubDir\'
        }
        It 'Adds a new file' {
            New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
            $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File' -Id 0)
            $Data.Count | Should Be 1
            $Data[0].LocationId | Should Be 0
            $Data[0].Name | Should Be 'Video'
            $Data[0].FileName | Should Be 'Video.mp4'
            $Data[0].Path | Should Be '\'
        }
        It 'Adds a second file' {
            New-VideoFile -Path TestDrive:\VideoLocation\SubDir\Video2.mp4
            $Data = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'File')
            $Data.Count | Should Be 2
        }
        It 'Retrieves a file by ID' {
            $Data = @(Get-VideoFile -Id 0)
            $Data.Count | Should Be 1
            $Data[0].LocationId | Should Be 0
            $Data[0].Name | Should Be 'Video'
            $Data[0].FileName | Should Be 'Video.mp4'
            $Data[0].Path | Should Be '\'
        }
        It 'Retrieves a file by name' {
            $Data = @(Get-VideoFile -Name 'Video')
            $Data.Count | Should Be 1
            $Data[0].LocationId | Should Be 0
            $Data[0].Name | Should Be 'Video'
            $Data[0].FileName | Should Be 'Video.mp4'
            $Data[0].Path | Should Be '\'
        }
        It 'Retrieves a file by path' {
            $Data = @(Get-VideoFile -Path '\')
            $Data.Count | Should Be 1
            $Data[0].LocationId | Should Be 0
            $Data[0].Name | Should Be 'Video'
            $Data[0].FileName | Should Be 'Video.mp4'
            $Data[0].Path | Should Be '\'
        }
        It 'Retrieves all files' {
            $Data = @(Get-VideoFile -All)
            $Data.Count | Should Be 2
        }
        It 'Tests for existence of a file' {
            Test-VideoFile -Path TestDrive:\VideoLocation\Video.mp4 | Should Be $true
        }
        It 'Removes a file' {
            $Data = @(Get-VideoFile -All)
            $Data | ForEach-Object {
                Remove-VideoFile -Id $_.Id
            }
            $DeletedItem = @(Get-VideoFile -All | Where-Object {$_.FullPath -ieq $Item.FullPath})
            $DeletedItem.Count | Should Be 0
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
    }
    Context 'Video management' {
        It 'Fails to add a second video for a file' {
            $File = New-VideoFile -Path TestDrive:\VideoLocation\Video2.mp4
            { New-Video -FileId $File.Id } | Should Not Throw
            { New-Video -FileId $File.Id } | Should Throw
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $File = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $File.Id
        $File = New-VideoFile -Path TestDrive:\VideoLocation\SubDir\Video2.mp4
        New-Video -FileId $File.Id
        It 'Retrieves a video by ID' {
            $Item = @(Get-Video -Id 0)
            $Item.Count | Should Be 1
        }
        It 'Retrieves a video by file ID' {
            $Item = @(Get-Video -FileId 0)
            $Item.Count | Should Be 1
        }
        It 'Retrieves all videos' {
            $Item = @(Get-Video -All)
            $Item.Count | Should Be 2
        }
        It 'Tests for video existence' {
            $File = @(Get-VideoFile -All)[0]
            Test-Video -FileId $File.Id | Should Be $true
            Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
            Test-Video -FileId 0 | Should Be $false
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $File = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $File.Id
        $File = New-VideoFile -Path TestDrive:\VideoLocation\SubDir\Video2.mp4
        New-Video -FileId $File.Id
        It 'Removes one of many videos' {
            $Video = @(Get-Video -All)[0]
            Remove-Video -FileId $Video.FileId
            $Data = @(Get-Video -All)
            $Data.Count | Should Be 1
        }
        It 'Removes last video' {
            $Video = @(Get-Video -All)[0]
            Remove-Video -FileId $Video.FileId
            $Data = @(Get-Video -All)
            $Data.Count | Should Be 0
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $Video1 = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $Video1.Id
        $Video2 = New-VideoFile -Path TestDrive:\VideoLocation\SubDir\Video2.mp4
        New-Video -FileId $Video2.Id
        It 'Updates a video' {
            Set-Video -Id $Video1.Id -NextId $Video2.Id
            $Video = Get-Video -Id $Video1.Id
            $Video.NextId | Should Be $Video2.Id
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
    }
    Context 'Tag management' {
        It 'Fails test for a non-existent tag' {
            Test-Tag -Name 'NonExistentTag' | Should Be $false
        }
        It 'Adds a new tag' {
            New-Tag -Name 'TestTag'
            $Tag = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Tag')
            $Tag.Count | Should Be 1
            $Tag[0].Name | Should Be 'TestTag'
        }
        It 'Completes test for existing tag' {
            Test-Tag -Name 'TestTag' | Should Be $true
        }
        It 'Retrieves a tag by ID' {
            $Tag = @(Get-Tag -Id 0)
            $Tag.Count | Should Be 1
            $Tag[0].Name | Should Be 'TestTag'
        }
        It 'Retrieves a tag by name' {
            $Tag = @(Get-Tag -Name 'TestTag')
            $Tag.Count | Should Be 1
            $Tag[0].Name | Should Be 'TestTag'
        }
        It 'Retrieves all tags' {
            $Tag = @(Get-Tag -All)
            $Tag.Count | Should Be 1
            $Tag[0].Name | Should Be 'TestTag'
        }
        It 'Updates the tag name' {
            $Tag = @(Get-Tag -All)[0]
            Set-Tag -Id $Tag.Id -Name 'TestTag2'
            $Tag = Get-Tag -Id $Tag.Id
            $Tag.Name | Should Be 'TestTag2'
        }
        New-Tag -Name 'TestTag'
        It 'Removes a tag' {
            $Tag = @(Get-Tag -All)[0]
            Remove-Tag -Id $Tag.Id
            $Data = @(Get-Tag -All)
            $Data.Count | Should Be 1
        }
        It 'Removes last tag' {
            $Tag = @(Get-Tag -All)[0]
            Remove-Tag -Id $Tag.Id
            $Data = @(Get-Tag -All)
            $Data.Count | Should Be 0
        }
    }
    Context 'Tag assignment' {
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Tag'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $File = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $File.Id
        $Video = Get-Video -FileId $File.Id
        $Tag = New-Tag -Name 'TestTag'
        It 'Fails test for non-existent tag on video' {
            Test-VideoTag -VideoId $Video.Id -TagId $Tag.Id | Should Be $false
            Test-VideoTag -VideoId $Video.Id -TagName 'TestTag' | Should Be $false
        }
        It 'Adds new tag on video' {
            Add-VideoTag -VideoId $Video.Id -TagId $Tag.Id
            $VideoTag = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'TagToVideo' | Where-Object {$_.TagId -eq $Tag.Id})
            $VideoTag.Count | Should Be 1
        }
        It 'Tests for existent tag on video' {
            Test-VideoTag -VideoId $Video.Id -TagId $Tag.Id | Should Be $true
            Test-VideoTag -VideoId $Video.Id -TagName 'TestTag' | Should Be $true
        }
        It 'Throws if adding a tag to video that is already present' {
            { Add-VideoTag -VideoId $Video.Id -TagId $Tag.Id } | Should Throw
            { Add-VideoTag -VideoId $Video.Id -TagName 'TestTag' } | Should Throw
        }
        It 'Retrieves a video tag by ID' {
            $Data = @(Get-VideoTag -VideoId $Video.Id -TagId $Tag.Id)
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].TagId | Should Be $Tag.Id
        }
        It 'Retrieves a video tag by name' {
            $Data = @(Get-VideoTag -VideoId $Video.Id -TagName 'TestTag')
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].TagId | Should Be $Tag.Id
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'TagToVideo'
        It 'Removes a video tag by ID' {
            Add-VideoTag -VideoId $Video.Id -TagId $Tag.Id
            Remove-VideoTag -VideoId $Video.Id -TagId $Tag.Id
            Test-VideoTag -VideoId $Video.Id -TagId $Tag.Id | Should Be $false
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'TagToVideo'
        It 'Removes a video tag by name' {
            Add-VideoTag -VideoId $Video.Id -TagId $Tag.Id
            Remove-VideoTag -VideoId $Video.Id -TagName 'TestTag'
            Test-VideoTag -VideoId $Video.Id -TagId $Tag.Id | Should Be $false
        }
    }
    Context 'Person management' {
        It 'Fails test for a non-existent Person' {
            Test-Person -Name 'NonExistentPerson' | Should Be $false
        }
        It 'Adds a new tag' {
            New-Person -Name 'TestPerson'
            $Person = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Person')
            $Person.Count | Should Be 1
            $Person[0].Name | Should Be 'TestPerson'
        }
        It 'Completes test for existing Person' {
            Test-Person -Name 'TestPerson' | Should Be $true
        }
        It 'Retrieves a person by ID' {
            $Person = @(Get-Person -Id 0)
            $Person.Count | Should Be 1
            $Person[0].Name | Should Be 'TestPerson'
        }
        It 'Retrieves a person by name' {
            $Person = @(Get-Person -Name 'TestPerson')
            $Person.Count | Should Be 1
            $Person[0].Name | Should Be 'TestPerson'
        }
        It 'Retrieves all persones' {
            $Person = @(Get-Person -All)
            $Person.Count | Should Be 1
            $Person[0].Name | Should Be 'TestPerson'
        }
        It 'Updates the person name' {
            $Person = @(Get-Person -All)[0]
            Set-Person -Id $Person.Id -Name 'TestPerson2'
            $Person = Get-Person -Id $Person.Id
            $Person.Name | Should Be 'TestPerson2'
        }
        New-Person -Name 'TestPerson'
        It 'Removes a person' {
            $Person = @(Get-Person -All)[0]
            Remove-Person -Id $Person.Id
            $Data = @(Get-Person -All)
            $Data.Count | Should Be 1
        }
        It 'Removes last person' {
            $Person = @(Get-Person -All)[0]
            Remove-Person -Id $Person.Id
            $Data = @(Get-Person -All)
            $Data.Count | Should Be 0
        }
    }
    Context 'Person assignment' {
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Person'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $File = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $File.Id
        $Video = Get-Video -FileId $File.Id
        $Person = New-Person -Name 'TestPerson'
        It 'Fails test for non-existent person on video' {
            Test-VideoPerson -VideoId $Video.Id -PersonId $Person.Id | Should Be $false
            Test-VideoPerson -VideoId $Video.Id -PersonName 'TestPerson' | Should Be $false
        }
        It 'Adds new person on video' {
            Add-VideoPerson -VideoId $Video.Id -PersonId $Person.Id
            $VideoPerson = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo' | Where-Object {$_.PersonId -eq $Person.Id})
            $VideoPerson.Count | Should Be 1
        }
        It 'Tests for existent person on video' {
            Test-VideoPerson -VideoId $Video.Id -PersonId $Person.Id | Should Be $true
            Test-VideoPerson -VideoId $Video.Id -PersonName 'TestPerson' | Should Be $true
        }
        It 'Throws if adding a person to video that is already present' {
            { Add-VideoPerson -VideoId $Video.Id -PersonId $Person.Id } | Should Throw
            { Add-VideoPerson -VideoId $Video.Id -PersonName 'TestPerson' } | Should Throw
        }
        It 'Retrieves a video person by ID' {
            $Data = @(Get-VideoPerson -VideoId $Video.Id -PersonId $Person.Id)
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].PersonId | Should Be $Person.Id
        }
        It 'Retrieves a video person by name' {
            $Data = @(Get-VideoPerson -VideoId $Video.Id -PersonName 'TestPerson')
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].PersonId | Should Be $Person.Id
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo'
        It 'Removes a video person by ID' {
            Add-VideoPerson -VideoId $Video.Id -PersonId $Person.Id
            Remove-VideoPerson -VideoId $Video.Id -PersonId $Person.Id
            Test-VideoPerson -VideoId $Video.Id -PersonId $Person.Id | Should Be $false
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo'
        It 'Removes a video person by name' {
            Add-VideoPerson -VideoId $Video.Id -PersonId $Person.Id
            Remove-VideoPerson -VideoId $Video.Id -PersonName 'TestPerson'
            Test-VideoPerson -VideoId $Video.Id -PersonId $Person.Id | Should Be $false
        }
    }
    Context 'Playlist management' {
        It 'Fails test for a non-existent playlist' {
            Test-Playlist -Name 'NonExistentPlaylist' | Should Be $false
        }
        It 'Adds a new playlist' {
            New-Playlist -Name 'TestPlaylist'
            $Playlist = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'Playlist')
            $Playlist.Count | Should Be 1
            $Playlist[0].Name | Should Be 'TestPlaylist'
        }
        It 'Completes test for existing playlist' {
            Test-Playlist -Name 'TestPlaylist' | Should Be $true
        }
        It 'Retrieves a playlist by ID' {
            $Playlist = @(Get-Playlist -Id 0)
            $Playlist.Count | Should Be 1
            $Playlist[0].Name | Should Be 'TestPlaylist'
        }
        It 'Retrieves a playlist by name' {
            $Playlist = @(Get-Playlist -Name 'TestPlaylist')
            $Playlist.Count | Should Be 1
            $Playlist[0].Name | Should Be 'TestPlaylist'
        }
        It 'Retrieves all playlists' {
            $Playlist = @(Get-Playlist -All)
            $Playlist.Count | Should Be 1
            $Playlist[0].Name | Should Be 'TestPlaylist'
        }
        It 'Updates the playlist name' {
            $Playlist = @(Get-Playlist -All)[0]
            Set-Playlist -Id $Playlist.Id -Name 'TestPlaylist2'
            $Playlist = Get-Playlist -Id $Playlist.Id
            $Playlist.Name | Should Be 'TestPlaylist2'
        }
        New-Playlist -Name 'TestPlaylist'
        It 'Removes a playlist' {
            $Playlist = @(Get-Playlist -All)[0]
            Remove-Playlist -Id $Playlist.Id
            $Data = @(Get-Playlist -All)
            $Data.Count | Should Be 1
        }
        It 'Removes last playlist' {
            $Playlist = @(Get-Playlist -All)[0]
            Remove-Playlist -Id $Playlist.Id
            $Data = @(Get-Playlist -All)
            $Data.Count | Should Be 0
        }
    }
    Context 'Playlist item management' {
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Playlist'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
        $File = New-VideoFile -Path TestDrive:\VideoLocation\Video.mp4
        New-Video -FileId $File.Id
        $Video = Get-Video -FileId $File.Id
        $Playlist = New-Playlist -Name 'TestPlaylist'
        It 'Fails test for non-existent person on video' {
            Test-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id | Should Be $false
            Test-PlaylistItem -VideoId $Video.Id -PlaylistName 'TestPlaylist' | Should Be $false
        }
        It 'Adds new person on video' {
            Add-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id
            $PlaylistItem = @(Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist' | Where-Object {$_.PlaylistId -eq $Playlist.Id})
            $PlaylistItem.Count | Should Be 1
        }
        It 'Tests for existent person on video' {
            Test-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id | Should Be $true
            Test-PlaylistItem -VideoId $Video.Id -PlaylistName 'TestPlaylist' | Should Be $true
        }
        It 'Throws if adding a person to video that is already present' {
            { Add-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id } | Should Throw
            { Add-PlaylistItem -VideoId $Video.Id -PlaylistName 'TestPlaylist' } | Should Throw
        }
        It 'Retrieves a video person by ID' {
            $Data = @(Get-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id)
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].PlaylistId | Should Be $Playlist.Id
        }
        It 'Retrieves a video person by name' {
            $Data = @(Get-PlaylistItem -VideoId $Video.Id -PlaylistName 'TestPlaylist')
            $Data.Count | Should Be 1
            $Data[0].VideoId | Should Be $Video.Id
            $Data[0].PlaylistId | Should Be $Playlist.Id
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist'
        It 'Removes a video person by ID' {
            Add-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id
            Remove-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id
            Test-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id | Should Be $false
        }
        Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'VideoToPlaylist'
        It 'Removes a video person by name' {
            Add-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id
            Remove-PlaylistItem -VideoId $Video.Id -PlaylistName 'TestPlaylist'
            Test-PlaylistItem -VideoId $Video.Id -PlaylistId $Playlist.Id | Should Be $false
        }
    }
    Context 'Bookmark management' {}
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Person'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'TagToVideo'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Tag'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
    It 'Imports videos' {
        @(
            "TestDrive:\VideoLocation\Video.mp4"
            "TestDrive:\VideoLocation\Video2.mp4"
            "TestDrive:\VideoLocation\SubDir\Video.mp4"
            "TestDrive:\VideoLocation\SubDir\Video2.mp4"
        ) | Import-Video
        @(Get-Tag -All).Count | Should Be 1
        (Get-Video -All).Count | Should Be 4
        (Get-CliXmlDatabaseItem -ConnectionName 'VideoDatabase' -TableName 'TagToVideo').Count | Should Be 4
    }
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'PersonToVideo'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Person'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'TagToVideo'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Tag'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Video'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'File'
    Clear-CliXmlDatabaseTable -ConnectionName 'VideoDatabase' -TableName 'Location'
    @(
        "TestDrive:\VideoLocation\Video.mp4"
        "TestDrive:\VideoLocation\Video2.mp4"
        "TestDrive:\VideoLocation\SubDir\Video.mp4"
        "TestDrive:\VideoLocation\SubDir\Video2.mp4"
    ) | ForEach-Object {
        New-Item -Path $_ -ItemType File -Force
    }
    It 'Imports a path' {
        $LocationPath = (Get-Item -Path TestDrive:\VideoLocation).FullName
        Import-VideoLocation -Name 'Pester' -Path $LocationPath
    }
    Close-VideoDatabase
}