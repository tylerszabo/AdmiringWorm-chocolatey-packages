﻿param($include = $null)

Import-Module AU
Import-Module "$PSScriptRoot\..\..\scripts\au_extensions.psm1"

$releases = 'https://teeworlds.com/?page=downloads'

function global:au_BeforeUpdate { Get-RemoteFiles -Purge -NoSuffix }

function global:au_SearchReplace {
  @{
    ".\legal\VERIFICATION.txt"      = @{
      "(?i)(^\s*location on\:?\s*)\<.*\>" = "`${1}<$releases>"
      "(?i)(\s*1\..+)\<.*\>"              = "`${1}<$($Latest.URL32)>"
      "(?i)(^\s*checksum\s*type\:).*"     = "`${1} $($Latest.ChecksumType32)"
      "(?i)(^\s*checksum(32)?\:).*"       = "`${1} $($Latest.Checksum32)"
    }
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)(^\s*file\s*=\s*`"[$]toolsPath\\).*" = "`${1}$($Latest.FileName32)`""
    }
  }
}

function global:au_AfterUpdate {
  $releaseNotes = "
[Software Changelog]($($Latest.ReleaseNotes)
[Package Changelog](https://github.com/AdmiringWorm/chocolatey-packages/blob/master/teeworlds/Changelog.md)
    "
  Update-Metadata -key "releaseNotes" -value $releaseNotes
  Update-Changelog -useIssueTitle
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

  $re = 'win32\.zip$'
  $urls = $download_page.Links | ? href -match $re | select -first 1 -expand href

  $streams = @{ }

  $verRe = '[-]'
  $urls | % {
    $version32 = $urls -split "$verRe" | select -last 1 -skip 1
    $releaseNotes = $download_page.links | ? OuterHtml -match ('\>' + [regex]::Escape($version32) + '\<') | select -first 1 -expand href | % { 'https://teeworlds.com/' + $_ }

    $streams.Add($version32, @{ URL32 = $_ ; Version = $version32; ReleaseNotes = $releaseNotes })
  }

  return @{ Streams = $streams }
}

update -ChecksumFor none -Include $include
