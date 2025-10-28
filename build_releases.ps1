# ===================================================================
# Flutter Build Script for Template Projects (PowerShell)
# Generates both signed app bundles and testing APKs
# ===================================================================

Write-Host ""
Write-Host "========================================"
Write-Host "Flutter Template Build Script"
Write-Host "========================================"
Write-Host ""

# Check if Flutter is available
try {
    flutter --version | Out-Null
} catch {
    Write-Error "ERROR: Flutter is not installed or not in PATH"
    Write-Host "Please install Flutter and add it to your PATH"
    Read-Host "Press Enter to continue"
    exit 1
}

# Get app name from pubspec.yaml
$appName = (Get-Content pubspec.yaml | Select-String "^name:").ToString().Split()[1]
Write-Host "Building: $appName"
Write-Host ""

# Check if key.properties exists
$signingStatus = ""
if (Test-Path "android\key.properties") {
    Write-Host "[INFO] key.properties found - will build signed releases" -ForegroundColor Green
    $signingStatus = "SIGNED"
} else {
    Write-Host "[WARNING] key.properties not found - using debug signing" -ForegroundColor Yellow
    Write-Host "[INFO] Copy android\key.properties.template to android\key.properties and configure for production signing"
    $signingStatus = "DEBUG_SIGNED"
}
Write-Host ""

# Clean previous builds
Write-Host "Cleaning previous builds..."
flutter clean
Write-Host ""

# Get dependencies
Write-Host "Getting dependencies..."
flutter pub get
Write-Host ""

Write-Host "========================================"
Write-Host "Building APK for Testing"
Write-Host "========================================"
Write-Host ""
flutter build apk --build-name="1.0.0+test" --target-platform android-arm,android-arm64,android-x64 --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: APK build failed"
    Read-Host "Press Enter to continue"
    exit 1
}
Write-Host "[SUCCESS] Testing APK built successfully!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""

Write-Host "========================================"
Write-Host "Building App Bundle for Play Store"
Write-Host "========================================"
Write-Host ""
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERROR: App Bundle build failed"
    Read-Host "Press Enter to continue"
    exit 1
}
Write-Host "[SUCCESS] App Bundle built successfully!" -ForegroundColor Green
Write-Host "Location: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Signing Status: $signingStatus"
Write-Host ""

# Copy builds to releases folder
if (-not (Test-Path "releases")) {
    New-Item -ItemType Directory -Path "releases" | Out-Null
}
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "releases\$appName-testing.apk"
Copy-Item "build\app\outputs\bundle\release\app-release.aab" "releases\$appName-playstore.aab"

Write-Host "========================================"
Write-Host "Build Summary"
Write-Host "========================================"
Write-Host "App Name: $appName"
Write-Host "Signing: $signingStatus"
Write-Host ""
Write-Host "Files created in releases\ folder:"
Write-Host "- $appName-testing.apk (for testing)"
Write-Host "- $appName-playstore.aab (for Play Store)"
Write-Host ""
Write-Host "[SUCCESS] All builds completed successfully!" -ForegroundColor Green

if ($signingStatus -eq "DEBUG_SIGNED") {
    Write-Host ""
    Write-Host "[IMPORTANT] For production releases:" -ForegroundColor Yellow
    Write-Host "1. Copy android\key.properties.template to android\key.properties"
    Write-Host "2. Configure your actual keystore details"
    Write-Host "3. Run this script again for properly signed releases"
}

Write-Host ""
Read-Host "Press Enter to continue"
