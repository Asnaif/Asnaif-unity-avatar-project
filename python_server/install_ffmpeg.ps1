# FFmpeg Installation Script for Windows
# Run this script as Administrator if using Chocolatey

Write-Host "=== FFmpeg Installation Helper ===" -ForegroundColor Cyan
Write-Host ""

# Check if ffmpeg is already installed
if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "✅ ffmpeg is already installed!" -ForegroundColor Green
    ffmpeg -version | Select-Object -First 3
    exit 0
}

Write-Host "❌ ffmpeg is not installed." -ForegroundColor Red
Write-Host ""

# Method selection
Write-Host "Select installation method:" -ForegroundColor Yellow
Write-Host "1. Winget (Recommended - Windows 10/11 built-in)"
Write-Host "2. Scoop (Requires Scoop package manager)"
Write-Host "3. Chocolatey (Requires Admin - may have permission issues)"
Write-Host "4. Manual download instructions"
Write-Host ""

$choice = Read-Host "Enter choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host "Installing via Winget..." -ForegroundColor Cyan
        winget install ffmpeg
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Installation successful!" -ForegroundColor Green
        } else {
            Write-Host "❌ Installation failed. Try another method." -ForegroundColor Red
        }
    }
    "2" {
        Write-Host "Checking if Scoop is installed..." -ForegroundColor Cyan
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            Write-Host "Installing via Scoop..." -ForegroundColor Cyan
            scoop install ffmpeg
        } else {
            Write-Host "❌ Scoop is not installed." -ForegroundColor Red
            Write-Host "Install Scoop first:" -ForegroundColor Yellow
            Write-Host "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
            Write-Host "irm get.scoop.sh | iex"
        }
    }
    "3" {
        Write-Host "Attempting Chocolatey installation..." -ForegroundColor Cyan
        Write-Host "⚠️  This requires Administrator privileges." -ForegroundColor Yellow
        
        # Try to remove lock file if exists
        $lockFile = "C:\ProgramData\chocolatey\lib\c00565a56f0e64a50f2ea5badcb97694d43e0755"
        if (Test-Path $lockFile) {
            Write-Host "Removing lock file..." -ForegroundColor Yellow
            try {
                Remove-Item $lockFile -Force -ErrorAction Stop
                Write-Host "✅ Lock file removed." -ForegroundColor Green
            } catch {
                Write-Host "❌ Could not remove lock file. Run PowerShell as Administrator." -ForegroundColor Red
            }
        }
        
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install ffmpeg -y
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Installation successful!" -ForegroundColor Green
            } else {
                Write-Host "❌ Installation failed. Try running as Administrator or use another method." -ForegroundColor Red
            }
        } else {
            Write-Host "❌ Chocolatey is not installed." -ForegroundColor Red
        }
    }
    "4" {
        Write-Host ""
        Write-Host "=== Manual Installation Instructions ===" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. Download FFmpeg:" -ForegroundColor Yellow
        Write-Host "   https://www.gyan.dev/ffmpeg/builds/" -ForegroundColor White
        Write-Host "   Download: ffmpeg-release-essentials.zip" -ForegroundColor White
        Write-Host ""
        Write-Host "2. Extract to: C:\ffmpeg\" -ForegroundColor Yellow
        Write-Host "   (Final path: C:\ffmpeg\bin\ffmpeg.exe)" -ForegroundColor White
        Write-Host ""
        Write-Host "3. Add to PATH:" -ForegroundColor Yellow
        Write-Host "   - Win + X → System → Advanced system settings" -ForegroundColor White
        Write-Host "   - Environment Variables → System variables → Path → Edit" -ForegroundColor White
        Write-Host "   - Add: C:\ffmpeg\bin" -ForegroundColor White
        Write-Host ""
        Write-Host "4. Restart terminal and verify:" -ForegroundColor Yellow
        Write-Host "   ffmpeg -version" -ForegroundColor White
        Write-Host ""
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
    }
}

# Verify installation
Write-Host ""
Write-Host "Verifying installation..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
    Write-Host "✅ ffmpeg is now installed!" -ForegroundColor Green
    Write-Host ""
    ffmpeg -version | Select-Object -First 3
} else {
    Write-Host "❌ ffmpeg is still not found in PATH." -ForegroundColor Red
    Write-Host "Please restart your terminal after installation." -ForegroundColor Yellow
    Write-Host "Or check INSTALL_FFMPEG.md for detailed instructions." -ForegroundColor Yellow
}

