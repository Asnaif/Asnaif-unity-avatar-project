@echo off
echo ========================================
echo InterPrep - Android Build Script
echo ========================================
echo.

echo [1/5] Checking Flutter installation...
flutter doctor
echo.

echo [2/5] Getting Flutter packages...
flutter pub get
echo.

echo [3/5] Checking connected devices...
flutter devices
echo.

echo [4/5] Building and running on Android...
echo.
echo Note: Make sure you have:
echo   - Android device connected OR
echo   - Android emulator running
echo.

flutter run

pause












