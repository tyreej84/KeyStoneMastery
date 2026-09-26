param(
    [string]$Version = "2.0.9"
)

$ErrorActionPreference = "Stop"
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must have the form x.y.z"
}

$repo = Split-Path -Parent $PSScriptRoot
$releaseRoot = Join-Path $repo ("Releases\" + $Version)
$pkg = Join-Path $releaseRoot "KeyStoneMastery"
$zip = Join-Path $releaseRoot ("KeyStoneMastery-" + $Version + ".zip")

if (Test-Path $pkg) {
    $resolvedPackage = (Resolve-Path -LiteralPath $pkg).Path
    if ($resolvedPackage -ne [IO.Path]::GetFullPath($pkg) -or
        -not $resolvedPackage.StartsWith($repo + [IO.Path]::DirectorySeparatorChar)) {
        throw "Package cleanup path is outside the repository"
    }
    Remove-Item -LiteralPath $resolvedPackage -Recurse -Force
}
New-Item -ItemType Directory -Path $pkg | Out-Null

# Intentionally exclude README.md and CHANGELOG.md from shipped addon package.
$files = @(
    "KeyStoneMastery.lua",
    "KeyStoneMastery.Chat.lua",
    "KeyStoneMastery.Constants.lua",
    "KeyStoneMastery.Data.lua",
    "KeyStoneMastery.GuildUtils.lua",
    "KeyStoneMastery.RunState.lua",
    "KeyStoneMastery.Sync.lua",
    "KeyStoneMastery.UI.KSM.lua",
    "KeyStoneMastery.UIIsolation.lua",
    "KeyStoneMastery.Utils.lua",
    "KeyStoneMastery.toc",
    "LICENSE"
)

foreach ($file in $files) {
    Copy-Item (Join-Path $repo $file) (Join-Path $pkg $file) -Force
}

Copy-Item (Join-Path $repo "Assets") (Join-Path $pkg "Assets") -Recurse -Force

if (Test-Path $zip) {
    Remove-Item $zip -Force
}
$installer = Join-Path $releaseRoot "Install-KeyStoneMastery.ps1"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "Install-KeyStoneMastery.ps1") -Destination $installer -Force
Compress-Archive -Path $pkg, $installer -DestinationPath $zip -CompressionLevel Optimal -Force

$copyToShelf = Join-Path (Split-Path -Parent $repo) "tools\copy-release-to-shelf.ps1"
& $copyToShelf -AddonName "KeyStoneMastery" -Version $Version -ZipPath $zip

$z = Get-Item $zip
Write-Output ("ZIP_OK " + $z.FullName)
Write-Output ("ZIP_SIZE_BYTES " + $z.Length)
Write-Output ("ZIP_LAST_WRITE " + $z.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss"))
