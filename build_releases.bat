@echo off
REM ===================================================================
REM Flutter Build Script for Template Projects
REM Generates both signed app bundles and testing APKs
REM ===================================================================

echo.
echo ========================================
echo Flutter Template Build Script
echo ========================================
echo.

REM Check if Flutter is available
flutter --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

REM Get app name from pubspec.yaml
for /f "tokens=2 delims= " %%a in ('findstr "^name:" pubspec.yaml') do set APP_NAME=%%a
echo Building: %APP_NAME%
echo.

REM Check if key.properties exists
if exist "android\key.properties" (
    echo [INFO] key.properties found - will build signed releases
    set SIGNING_STATUS=SIGNED
) else (
    echo [WARNING] key.properties not found - using debug signing
    echo [INFO] Copy android\key.properties.template to android\key.properties and configure for production signing
    set SIGNING_STATUS=DEBUG_SIGNED
)
echo.

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
echo.

REM Get dependencies
echo Getting dependencies...
flutter pub get
echo.

echo ========================================
echo Building APK for Testing (releaseTest)
echo ========================================
echo.
flutter build apk --build-name=1.0.0+test --flavor= --target-platform android-arm,android-arm64,android-x64 --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: APK build failed
    pause
    exit /b 1
)
echo [SUCCESS] Testing APK built successfully!
echo Location: build\app\outputs\flutter-apk\app-release.apk
echo.

echo ========================================
echo Building App Bundle for Play Store
echo ========================================
echo.
flutter build appbundle --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: App Bundle build failed
    pause
    exit /b 1
)
echo [SUCCESS] App Bundle built successfully!
echo Location: build\app\outputs\bundle\release\app-release.aab
echo Signing Status: %SIGNING_STATUS%
echo.

REM Copy builds to releases folder
if not exist "releases" mkdir releases
copy "build\app\outputs\flutter-apk\app-release.apk" "releases\%APP_NAME%-testing.apk" >nul
copy "build\app\outputs\bundle\release\app-release.aab" "releases\%APP_NAME%-playstore.aab" >nul

echo ========================================
echo Build Summary
echo ========================================
echo App Name: %APP_NAME%
echo Signing: %SIGNING_STATUS%
echo.
echo Files created in releases\ folder:
echo - %APP_NAME%-testing.apk (for testing)
echo - %APP_NAME%-playstore.aab (for Play Store)
echo.
echo [SUCCESS] All builds completed successfully!

if "%SIGNING_STATUS%"=="DEBUG_SIGNED" (
    echo.
    echo [IMPORTANT] For production releases:
    echo 1. Copy android\key.properties.template to android\key.properties
    echo 2. Configure your actual keystore details
    echo 3. Run this script again for properly signed releases
)

echo.
pause
