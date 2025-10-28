# Flutter Template Build Setup

This template project is configured for easy generation of both **signed app bundles** for Play Store distribution and **release APKs** for testing purposes.

## 🚀 Quick Start

### For New Projects from Template

1. **Configure App Details**: 
   - Update `lib/constants/my_app_urls.dart` with your app-specific information
   - Update `lib/constants/web_interceptors_config.dart` to intercept web elements (optional)
2. **Set up Signing** (for production): Follow the [Signing Setup](#signing-setup) section
3. **Build**: Run one of the provided build scripts

### Build Scripts Available

- **Windows Batch**: `build_releases.bat` (double-click to run)
- **PowerShell**: `build_releases.ps1` (right-click → Run with PowerShell)  
- **Unix/Linux/macOS**: `build_releases.sh` (run in terminal)

## 📱 What Gets Built

The build scripts generate:

| File | Purpose | Signing |
|------|---------|---------|
| `releases/[AppName]-testing.apk` | Testing on devices | Debug/Test signing |
| `releases/[AppName]-playstore.aab` | Play Store upload | Production signing* |

*Production signing only if `key.properties` is configured, otherwise debug signing

## 🔑 Signing Setup

### For Production Releases (Play Store)

1. **Create/Obtain Keystore**:
   ```bash
   # Create new keystore (if you don't have one)
   keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. **Configure Signing**:
   ```bash
   # Copy template
   cp android/key.properties.template android/key.properties
   ```

3. **Edit `android/key.properties`**:
   ```properties
   storeFile=../keystores/release-keystore.jks
   storePassword=your_actual_store_password
   keyAlias=release
   keyPassword=your_actual_key_password
   ```

4. **Create Keystores Directory**:
   ```bash
   mkdir android/keystores
   # Move your keystore file here
   ```

### For Testing Only

No setup required! The project automatically uses debug signing for testing APKs.

## 🛠 Build Configuration Details

### Build Types

| Build Type | Use Case | Signing | Output |
|------------|----------|---------|---------|
| `debug` | Development | Debug keystore | APK only |
| `release` | Production | Production keystore* | APK + Bundle |
| `releaseTest` | Testing | Debug keystore | APK only |

*Falls back to debug keystore if `key.properties` not found

### Gradle Configuration

The template includes smart signing configuration in `android/app/build.gradle.kts`:

- **Automatic keystore detection**: Uses production keystore if available, debug otherwise
- **Multiple signing configs**: Production, debug, and testing configurations  
- **Fallback handling**: Never fails due to missing production keystore

## 📂 Project Structure

```
your_project/
├── android/
│   ├── key.properties.template     # Template for signing config
│   ├── key.properties             # Your actual signing config (gitignored)
│   └── keystores/                 # Store your keystores here (gitignored)
├── lib/constants/
│   ├── my_app_urls.dart           # App URLs and settings
│   └── web_interceptors_config.dart  # Web element interceptions (optional)
├── releases/                      # Generated builds appear here
├── build_releases.bat             # Windows build script
├── build_releases.ps1             # PowerShell build script
├── build_releases.sh              # Unix build script
└── BUILD_SETUP.md                 # This documentation
```

## 🔄 Template Workflow

### When Creating New Project from Template

1. **Clone/Copy Template**
2. **Update App Configuration**:
   ```dart
   // lib/constants/my_app_urls.dart
   class Changes {
     static String mainUrl = 'https://your-new-app-domain.com';
     static String AppTitle = 'Your New App Name';
     static String oneSignalAppId = 'your-onesignal-id';
     // ... other app-specific settings
   }
   
   // lib/constants/web_interceptors_config.dart (optional)
   // Configure click interceptions and element hiding
   // See file for detailed instructions
   ```

3. **Update App Identity**:
   ```bash
   # Change package name
   flutter pub run change_app_package_name:main com.yourcompany.newapp
   
   # Change app name  
   flutter pub run rename setAppName --targets ios,android --value "New App Name"
   ```

4. **Set Up Signing** (if needed for production)
5. **Build**: Run build script

### For Testing/Development Builds

Simply run any build script - no signing setup required!

## 🚨 Security Notes

- `key.properties` is automatically gitignored
- Keystore files in `android/keystores/` are gitignored
- Never commit production keystores or passwords to version control
- Keep backup copies of your production keystores in a secure location

## 🐛 Troubleshooting

### Build Fails

1. **Check Flutter Installation**: `flutter doctor`
2. **Clean Project**: `flutter clean` then `flutter pub get`
3. **Check Dependencies**: Ensure all required dependencies are installed

### Signing Issues

1. **Production keystore not found**: Check `key.properties` path is correct
2. **Wrong password**: Verify keystore and key passwords in `key.properties`
3. **Debug signing for production**: Remove `key.properties` to use debug signing temporarily

### Script Permission Issues (Unix/Linux/macOS)

```bash
chmod +x build_releases.sh
./build_releases.sh
```

## 📋 Manual Build Commands

If you prefer manual control:

```bash
# Testing APK (debug signed)
flutter build apk --release

# Production App Bundle (production signed if configured)
flutter build appbundle --release

# Testing APK with custom build name
flutter build apk --build-name="1.0.0+test" --release
```

## 🎯 Benefits of This Setup

✅ **Template-friendly**: Easy to configure for new projects  
✅ **Dual-purpose**: Supports both testing and production builds  
✅ **Automatic fallback**: Never fails due to missing production keystore  
✅ **Secure**: Production credentials are gitignored  
✅ **Cross-platform**: Build scripts for Windows, macOS, and Linux  
✅ **Organized output**: All builds go to `releases/` folder with clear names

---

*This setup allows you to use this project as a template while maintaining the flexibility to generate both signed app bundles for distribution and release APKs for testing.*
