# RotaAssist Install Test Script (Windows PowerShell)
# Creates a symbolic link of the addon directory to the WoW AddOns folder.

$AddonName = "RotaAssist"
$SourceDir = Join-Path (Get-Location) "addon"

# Common WoW paths for Windows
$DefaultPaths = @(
    "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns",
    "C:\Program Files\World of Warcraft\_retail_\Interface\AddOns",
    "D:\Games\World of Warcraft\_retail_\Interface\AddOns"
)

$TargetPath = $args[0]

if (-not $TargetPath) {
    foreach ($path in $DefaultPaths) {
        if (Test-Path $path) {
            $TargetPath = $path
            break
        }
    }
}

if (-not $TargetPath -or -not (Test-Path $TargetPath)) {
    Write-Host "❌ Error: WoW AddOns directory not found!" -ForegroundColor Red
    Write-Host "Please provide the path as an argument, e.g.:"
    Write-Host ".\scripts\install_test.ps1 'C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns'"
    exit 1
}

$DestPath = Join-Path $TargetPath $AddonName

Write-Host "Checking installation at: $DestPath"

# Remove existing link or directory
if (Test-Path $DestPath) {
    Write-Host "Removing existing installation..."
    Remove-Item -Path $DestPath -Recurue -Force
}

# Create Symbolic Link (requires Developer Mode or Admin)
Write-Host "Creating symlink: $SourceDir -> $DestPath"
try {
    New-Item -ItemType SymbolicLink -Path $DestPath -Target $SourceDir -ErrorAction Stop
    Write-Host ""
    Write-Host "✅ RotaAssist installed! /reload in game to activate." -ForegroundColor Green
    Write-Host "✅ RotaAssist 已安装！在游戏中输入 /reload 激活。" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create symbolic link." -ForegroundColor Red
    Write-Host "Try running PowerShell as Administrator."
    Write-Host "Alternatively, copying files instead..."
    Copy-Item -Path $SourceDir -Destination $DestPath -Recurse
    Write-Host "✅ RotaAssist copied! /reload in game to activate." -ForegroundColor Green
}
