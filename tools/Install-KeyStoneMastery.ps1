param(
    [Parameter(Mandatory = $true)]
    [string]$WowRoot
)

# One-time folder/settings migration. Run with WoW closed, from an extracted release
# or this repository. Old names appear only here so existing installations can migrate.
$ErrorActionPreference = 'Stop'
if (Get-Process -Name Wow, WowT, WowB -ErrorAction SilentlyContinue) {
    throw 'Close World of Warcraft before migrating settings or installing the addon.'
}
$root = (Resolve-Path -LiteralPath $WowRoot).Path.TrimEnd('\', '/')
$addons = Join-Path $root 'Interface\AddOns'
$accounts = Join-Path $root 'WTF\Account'
if (-not (Test-Path -LiteralPath $addons -PathType Container)) {
    throw 'WowRoot must be the client directory containing Interface\AddOns.'
}
$source = Join-Path $PSScriptRoot 'KeyStoneMastery'
if (-not (Test-Path -LiteralPath (Join-Path $source 'KeyStoneMastery.toc'))) {
    $source = Split-Path -Parent $PSScriptRoot
}
$tocPath = Join-Path $source 'KeyStoneMastery.toc'
if (-not (Test-Path -LiteralPath $tocPath)) { throw 'Cannot find the release addon folder.' }
$destination = Join-Path $addons 'KeyStoneMastery'
$legacy = Join-Path $addons 'KeyMaster'
if (Test-Path -LiteralPath $destination) {
    throw 'KeyStoneMastery is already installed. This one-time migration will not overwrite it.'
}

# Stage every transformation before writing anything; never execute saved Lua data.
$migrations = @()
if (Test-Path -LiteralPath $accounts) {
    foreach ($file in Get-ChildItem -LiteralPath $accounts -Filter 'KeyMaster.lua' -Recurse -File) {
        if ($file.Directory.Name -ne 'SavedVariables') { continue }
        $target = Join-Path $file.DirectoryName 'KeyStoneMastery.lua'
        if (Test-Path -LiteralPath $target) { throw "Existing settings require manual review: $target" }
        $content = [IO.File]::ReadAllText($file.FullName)
        $pattern = '(?m)^KeyMasterDB(?=\s*=)'
        if ([regex]::Matches($content, $pattern).Count -ne 1) {
            throw "Expected exactly one saved database assignment: $($file.FullName)"
        }
        $migrations += [pscustomobject]@{
            Original = $file.FullName
            Target = $target
            Content = [regex]::Replace($content, $pattern, 'KeyStoneMasteryDB')
        }
    }
}
$addonLists = @()
if (Test-Path -LiteralPath $accounts) {
    foreach ($file in Get-ChildItem -LiteralPath $accounts -Filter 'AddOns.txt' -Recurse -File) {
        $content = [IO.File]::ReadAllText($file.FullName)
        $updated = [regex]::Replace($content, '(?m)^KeyMaster(?=\s*:)', 'KeyStoneMastery')
        if ($content -ne $updated) {
            if ($content -match '(?m)^KeyStoneMastery\s*:') {
                throw "Both addon names are in this enablement list; review it manually: $($file.FullName)"
            }
            $addonLists += [pscustomobject]@{ Original = $file.FullName; Content = $updated }
        }
    }
}
$runtimeFiles = @(Get-Content -LiteralPath $tocPath | Where-Object { $_.Trim() -and -not $_.StartsWith('#') })
foreach ($file in $runtimeFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $file))) { throw "Missing runtime file: $file" }
}
$backup = Join-Path $root ('KeyStoneMastery-MigrationBackup\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($entry in @($migrations) + @($addonLists)) {
    $relative = $entry.Original.Substring($root.Length + 1)
    $backupFile = Join-Path $backup $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupFile) -Force | Out-Null
    Copy-Item -LiteralPath $entry.Original -Destination $backupFile
}
New-Item -ItemType Directory -Path $destination | Out-Null
foreach ($file in @($runtimeFiles) + @('KeyStoneMastery.toc', 'LICENSE')) {
    Copy-Item -LiteralPath (Join-Path $source $file) -Destination (Join-Path $destination $file)
}
Copy-Item -LiteralPath (Join-Path $source 'Assets') -Destination $destination -Recurse
foreach ($file in @($runtimeFiles) + @('KeyStoneMastery.toc', 'LICENSE')) {
    if ((Get-FileHash -LiteralPath (Join-Path $source $file)).Hash -ne
        (Get-FileHash -LiteralPath (Join-Path $destination $file)).Hash) { throw "Copy verification failed: $file" }
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
foreach ($entry in $migrations) { [IO.File]::WriteAllText($entry.Target, $entry.Content, $utf8) }
foreach ($entry in $addonLists) { [IO.File]::WriteAllText($entry.Original, $entry.Content, $utf8) }
if (Test-Path -LiteralPath $legacy) {
    $resolvedLegacy = (Resolve-Path -LiteralPath $legacy).Path
    $archive = Join-Path $backup 'KeyMaster'
    if ($resolvedLegacy -ne [IO.Path]::GetFullPath($legacy) -or
        (Split-Path -Parent $resolvedLegacy) -ne $addons -or
        -not $archive.StartsWith($root + [IO.Path]::DirectorySeparatorChar)) {
        throw 'Legacy addon move must remain within the selected client directory.'
    }
    Move-Item -LiteralPath $resolvedLegacy -Destination $archive -Force
}
Write-Output "INSTALLED $destination"
Write-Output "MIGRATED_DATABASES $($migrations.Count)"
Write-Output "UPDATED_ENABLEMENT_LISTS $($addonLists.Count)"
Write-Output "BACKUP $backup"
