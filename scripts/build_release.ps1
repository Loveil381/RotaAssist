param (
    [Parameter(Mandatory=$true)]
    [string]$Version
)

$AddonName = "RotaAssist"
$BuildDir = "build"
$ZipFile = "${AddonName}-v${Version}.zip"

Write-Host "Building ${AddonName} v${Version}..." -ForegroundColor Cyan

if (Test-Path $BuildDir) {
    Remove-Item -Path $BuildDir -Recurse -Force
}

$AddonBuildPath = Join-Path $BuildDir $AddonName
New-Item -Path $AddonBuildPath -ItemType Directory -Force | Out-Null

# Copy addon files
Copy-Item -Path "addon\*" -Destination $AddonBuildPath -Recurse

# Remove unnecessary files
Get-ChildItem -Path $BuildDir -Filter ".DS_Store" -Recurse | Remove-Item -Force
Get-ChildItem -Path $BuildDir -Filter "*.bak" -Recurse | Remove-Item -Force
Get-ChildItem -Path $BuildDir -Filter ".git*" -Recurse | Remove-Item -Force
Remove-Item -Path (Join-Path $AddonBuildPath "Engine\Predictor.lua") -Force -ErrorAction SilentlyContinue

# Package
if (Test-Path $ZipFile) {
    Remove-Item -Path $ZipFile -Force
}

Compress-Archive -Path "$BuildDir\*" -DestinationPath $ZipFile

Write-Host "✅ Built: $ZipFile" -ForegroundColor Green
$file = Get-Item $ZipFile
Write-Host ("Size: {0:N2} KB" -f ($file.Length / 1KB))

Write-Host "📁 Contents:"
# Expand-Archive doesn't have a list mode, so we just finish here
