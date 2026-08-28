param(
    [string]$Version = "1.7.0"
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $repo ("Releases\" + $Version)
$pkg = Join-Path $releaseRoot "KeyMaster"
$zip = Join-Path $releaseRoot "KeyMaster.zip"

if (Test-Path $pkg) {
    Remove-Item $pkg -Recurse -Force
}
New-Item -ItemType Directory -Path $pkg | Out-Null

# Intentionally exclude README.md and CHANGELOG.md from shipped addon package.
$files = @(
    "KeyMaster.lua",
    "KeyMaster.Chat.lua",
    "KeyMaster.Constants.lua",
    "KeyMaster.Data.lua",
    "KeyMaster.GuildUtils.lua",
    "KeyMaster.RunState.lua",
    "KeyMaster.Sync.lua",
    "KeyMaster.UI.KSM.lua",
    "KeyMaster.Utils.lua",
    "KeyMaster.toc",
    "LICENSE"
)

foreach ($file in $files) {
    Copy-Item (Join-Path $repo $file) (Join-Path $pkg $file) -Force
}

Copy-Item (Join-Path $repo "Assets") (Join-Path $pkg "Assets") -Recurse -Force

if (Test-Path $zip) {
    Remove-Item $zip -Force
}
Compress-Archive -Path $pkg -DestinationPath $zip -CompressionLevel Optimal -Force

$copyToShelf = Join-Path (Split-Path -Parent $repo) "tools\copy-release-to-shelf.ps1"
& $copyToShelf -AddonName "KeyMaster" -Version $Version -ZipPath $zip

$z = Get-Item $zip
Write-Output ("ZIP_OK " + $z.FullName)
Write-Output ("ZIP_SIZE_BYTES " + $z.Length)
Write-Output ("ZIP_LAST_WRITE " + $z.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))
