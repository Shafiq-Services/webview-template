#!/bin/bash
# ===================================================================
# Flutter Build Script for Template Projects (Bash)
# Generates both signed app bundles and testing APKs
# ===================================================================

echo ""
echo "========================================"
echo "Flutter Template Build Script"
echo "========================================"
echo ""

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter is not installed or not in PATH"
    echo "Please install Flutter and add it to your PATH"
    read -p "Press Enter to continue..."
    exit 1
fi

# Get app name from pubspec.yaml
APP_NAME=$(grep "^name:" pubspec.yaml | awk '{print $2}')
echo "Building: $APP_NAME"
echo ""

# Check if key.properties exists
if [ -f "android/key.properties" ]; then
    echo "[INFO] key.properties found - will build signed releases"
    SIGNING_STATUS="SIGNED"
else
    echo "[WARNING] key.properties not found - using debug signing"
    echo "[INFO] Copy android/key.properties.template to android/key.properties and configure for production signing"
    SIGNING_STATUS="DEBUG_SIGNED"
fi
echo ""

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean
echo ""

# Get dependencies
echo "Getting dependencies..."
flutter pub get
echo ""

echo "========================================"
echo "Building APK for Testing"
echo "========================================"
echo ""
flutter build apk --build-name="1.0.0+test" --target-platform android-arm,android-arm64,android-x64 --release
if [ $? -ne 0 ]; then
    echo "ERROR: APK build failed"
    read -p "Press Enter to continue..."
    exit 1
fi
echo "[SUCCESS] Testing APK built successfully!"
echo "Location: build/app/outputs/flutter-apk/app-release.apk"
echo ""

echo "========================================"
echo "Building App Bundle for Play Store"
echo "========================================"
echo ""
flutter build appbundle --release
if [ $? -ne 0 ]; then
    echo "ERROR: App Bundle build failed"
    read -p "Press Enter to continue..."
    exit 1
fi
echo "[SUCCESS] App Bundle built successfully!"
echo "Location: build/app/outputs/bundle/release/app-release.aab"
echo "Signing Status: $SIGNING_STATUS"
echo ""

# Copy builds to releases folder
mkdir -p releases
cp "build/app/outputs/flutter-apk/app-release.apk" "releases/$APP_NAME-testing.apk"
cp "build/app/outputs/bundle/release/app-release.aab" "releases/$APP_NAME-playstore.aab"

echo "========================================"
echo "Build Summary"
echo "========================================"
echo "App Name: $APP_NAME"
echo "Signing: $SIGNING_STATUS"
echo ""
echo "Files created in releases/ folder:"
echo "- $APP_NAME-testing.apk (for testing)"
echo "- $APP_NAME-playstore.aab (for Play Store)"
echo ""
echo "[SUCCESS] All builds completed successfully!"

if [ "$SIGNING_STATUS" = "DEBUG_SIGNED" ]; then
    echo ""
    echo "[IMPORTANT] For production releases:"
    echo "1. Copy android/key.properties.template to android/key.properties"
    echo "2. Configure your actual keystore details"
    echo "3. Run this script again for properly signed releases"
fi

echo ""
read -p "Press Enter to continue..."
