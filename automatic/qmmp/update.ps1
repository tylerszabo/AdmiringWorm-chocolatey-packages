﻿param($include)

Import-Module AU

$releases = 'http://qmmp.ylsoftware.com/files/windows/?C=M;O=D'
$softwareName = 'Qt-based Multimedia Player'

function global:au_BeforeUpdate { Get-RemoteFiles -Purge -NoSuffix }

function global:au_AfterUpdate { Update-Changelog -useIssueTitle }

function global:au_SearchReplace {
  @{
    ".\legal\VERIFICATION.txt" = @{
      "(?i)(^\s*location on\:?\s*)\<.*\>" = "`${1}<$releases>"
      "(?i)(\s*1\..+)\<.*\>" = "`${1}<$($Latest.URL32)>"
      "(?i)(^\s*checksum\s*type\:).*" = "`${1} $($Latest.ChecksumType32)"
      "(?i)(^\s*checksum(32)?\:).*" = "`${1} $($Latest.Checksum32)"
    }
    ".\tools\chocolateyInstall.ps1" = @{
      "(?i)^(\s*softwareName\s*=\s*)'.*'" = "`${1}'$softwareName'"
      "(?i)(^\s*file\s*=\s*`"[$]toolsPath\\).*" = "`${1}$($Latest.FileName32)`""
    }
    ".\tools\chocolateyUninstall.ps1" = @{
      "(?i)^(\s*softwareName\s*=\s*)'.*'" = "`${1}'$softwareName'"
    }
  }
}

function global:au_GetLatest {
  $download_page = Invoke-WebRequest -Uri $releases -UseBasicParsing

  $re = '\.exe$'
  $urls = $download_page.Links | ? href -match $re | select -first 1 -expand href | % { 'http://qmmp.ylsoftware.com/files/windows/' + $_ }

  $streams = @{ }

  $urls | % {
    $verRe = '[-]'
    $version = $_ -split $verRe | select -last 1 -skip 1

    $streams.Add($version, @{ URL32 = [uri]$_ ; Version = [version]$version } )
  }

  return @{ Streams = $streams }
}

update -ChecksumFor none -Include $include
