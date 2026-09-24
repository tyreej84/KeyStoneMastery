$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('ksm-migration-test-' + [guid]::NewGuid().ToString('N'))
$installer = Join-Path $PSScriptRoot 'Install-KeyStoneMastery.ps1'
function Assert-True($condition, $message) {
    if (-not $condition) { throw $message }
}
function New-Fixture($name) {
    $client = Join-Path $testRoot $name
    New-Item -ItemType Directory -Path (Join-Path $client 'Interface\AddOns\KeyMaster') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $client 'WTF\Account\test\SavedVariables') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $client 'Interface\AddOns\KeyMaster\original.txt') -Value 'original addon'
    return $client
}
try {
    $client = New-Fixture 'success'
    $saved = Join-Path $client 'WTF\Account\test\SavedVariables'
    $oldFile = Join-Path $saved 'KeyMaster.lua'
    $oldText = 'KeyMasterDB = { ui = { scale = 1.2 }, note = "KeyMaster", characters = { player = { level = 90 } } }'
    Set-Content -LiteralPath $oldFile -Value $oldText -Encoding UTF8
    $hash = (Get-FileHash -LiteralPath $oldFile).Hash
    $addonList = Join-Path $client 'WTF\Account\test\AddOns.txt'
    Set-Content -LiteralPath $addonList -Value "KeyMaster: disabled`nUnrelated: enabled" -Encoding UTF8
    & $installer -WowRoot $client
    $newText = [IO.File]::ReadAllText((Join-Path $saved 'KeyStoneMastery.lua')).Trim()
    Assert-True ($newText -eq $oldText.Replace('KeyMasterDB =', 'KeyStoneMasteryDB =')) 'Database content changed beyond its global name'
    Assert-True ((Get-FileHash -LiteralPath $oldFile).Hash -eq $hash) 'Original settings were modified'
    Assert-True ((Get-Content -LiteralPath $addonList -Raw) -match 'KeyStoneMastery: disabled') 'Disabled state was not preserved'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $client 'Interface\AddOns\KeyMaster'))) 'Legacy addon can still load'
    Assert-True (Test-Path -LiteralPath (Join-Path $client 'Interface\AddOns\KeyStoneMastery\KeyStoneMastery.toc')) 'New addon missing'
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $client 'KeyStoneMastery-MigrationBackup') -Directory)
    Assert-True ($backups.Count -eq 1) 'Expected one backup'
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $backups[0].FullName 'WTF\Account\test\SavedVariables\KeyMaster.lua')).Hash -eq $hash) 'Settings backup differs'
    Assert-True (Test-Path -LiteralPath (Join-Path $backups[0].FullName 'KeyMaster\original.txt')) 'Legacy addon backup missing'
    $blocked = $false
    try { & $installer -WowRoot $client } catch { $blocked = $_.Exception.Message -match 'already installed' }
    Assert-True $blocked 'Repeated install should refuse to overwrite'

    $client = New-Fixture 'conflict'
    $saved = Join-Path $client 'WTF\Account\test\SavedVariables'
    Set-Content -LiteralPath (Join-Path $saved 'KeyMaster.lua') -Value $oldText
    Set-Content -LiteralPath (Join-Path $saved 'KeyStoneMastery.lua') -Value 'KeyStoneMasteryDB = { keep = true }'
    $blocked = $false
    try { & $installer -WowRoot $client } catch { $blocked = $_.Exception.Message -match 'Existing settings' }
    Assert-True $blocked 'Conflicting settings should block migration'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $client 'KeyStoneMastery-MigrationBackup'))) 'Conflict should fail before writes'

    $client = New-Fixture 'malformed'
    Set-Content -LiteralPath (Join-Path $client 'WTF\Account\test\SavedVariables\KeyMaster.lua') -Value 'UnexpectedDB = {}'
    $blocked = $false
    try { & $installer -WowRoot $client } catch { $blocked = $_.Exception.Message -match 'exactly one saved database' }
    Assert-True $blocked 'Unknown data format should block migration'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $client 'KeyStoneMastery-MigrationBackup'))) 'Malformed data should fail before writes'
    Write-Output 'PASS: settings preservation, enablement, backups, renamed installation, repeat refusal, conflict refusal, malformed-data refusal'
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolved = (Resolve-Path -LiteralPath $testRoot).Path
        if ($resolved -ne [IO.Path]::GetFullPath($testRoot) -or
            -not (Split-Path -Leaf $resolved).StartsWith('ksm-migration-test-')) { throw 'Unsafe test cleanup path' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
