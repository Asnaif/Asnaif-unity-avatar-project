# FFmpeg Installation Guide for Windows

## Problem
Chocolatey installation failed due to permission issues.

## Solution: Manual Installation

### Method 1: Direct Download (Recommended)

1. **Download FFmpeg:**
   - Visit: https://www.gyan.dev/ffmpeg/builds/
   - Download: `ffmpeg-release-essentials.zip` (latest version)
   - Or direct link: https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip

2. **Extract the ZIP file:**
   - Extract to: `C:\ffmpeg\`
   - Final path should be: `C:\ffmpeg\bin\ffmpeg.exe`

3. **Add to PATH:**
   - Press `Win + X` and select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "System variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\ffmpeg\bin`
   - Click "OK" on all dialogs

4. **Verify Installation:**
   ```powershell
   ffmpeg -version
   ```

### Method 2: Using Winget (Windows Package Manager)

```powershell
winget install ffmpeg
```

### Method 3: Fix Chocolatey Permission Issue

If you want to use Chocolatey, run PowerShell as Administrator:

```powershell
# Run PowerShell as Administrator
# Remove lock file
Remove-Item "C:\ProgramData\chocolatey\lib\c00565a56f0e64a50f2ea5badcb97694d43e0755" -Force -ErrorAction SilentlyContinue

# Try installing again
choco install ffmpeg -y
```

### Method 4: Using Scoop

```powershell
# Install Scoop first (if not installed)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install ffmpeg
scoop install ffmpeg
```

## After Installation

Restart your terminal/PowerShell and verify:
```powershell
ffmpeg -version
```

The Python server will automatically detect ffmpeg once it's in your PATH.

