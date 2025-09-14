# Android SDK Setup Guide

## 📱 Android SDK Configuration

### Current Project Settings
- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: 34 (Android 14)
- **Compile SDK**: 34 (Android 14)
- **NDK Version**: 25.1.8937393
- **Java Version**: 11
- **Kotlin JVM Target**: 11

### Why These Versions?
- **Min SDK 21**: Required for Firebase services and modern Android features
- **Target SDK 34**: Latest stable Android version for best compatibility
- **Java 11**: Required for modern Android development and Firebase
- **NDK 25.1.8937393**: Latest stable NDK for native code compilation

## 🛠️ Installation Steps

### Step 1: Install Android Studio
1. **Download Android Studio**: [https://developer.android.com/studio](https://developer.android.com/studio)
2. **Install Android Studio** with default settings
3. **Open Android Studio** and complete the setup wizard
4. **Install Android SDK** (will be prompted during setup)

### Step 2: Configure Android SDK
1. **Open Android Studio**
2. **Go to**: File → Settings (Windows/Linux) or Android Studio → Preferences (macOS)
3. **Navigate to**: Appearance & Behavior → System Settings → Android SDK
4. **SDK Platforms tab**: Install these versions:
   - ✅ **Android 14.0 (API 34)** - Target SDK
   - ✅ **Android 13.0 (API 33)** - Backup compatibility
   - ✅ **Android 12.0 (API 31)** - Wide device support
   - ✅ **Android 5.0 (API 21)** - Minimum SDK

5. **SDK Tools tab**: Install these tools:
   - ✅ **Android SDK Build-Tools 34.0.0**
   - ✅ **Android SDK Command-line Tools (latest)**
   - ✅ **Android SDK Platform-Tools**
   - ✅ **Android Emulator**
   - ✅ **Google Play services**
   - ✅ **Google USB Driver** (Windows only)
   - ✅ **Intel x86 Emulator Accelerator (HAXM installer)**

### Step 3: Set Environment Variables

#### Windows:
```cmd
# Set ANDROID_HOME
setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"

# Add to PATH
setx PATH "%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\build-tools\34.0.0"
```

#### macOS/Linux:
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# export ANDROID_HOME=$HOME/Android/Sdk        # Linux

export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
```

### Step 4: Accept Android Licenses
```bash
flutter doctor --android-licenses
```
**Accept all licenses** by typing 'y' when prompted.

### Step 5: Verify Installation
```bash
flutter doctor -v
```

**Expected output**:
```
[✓] Android toolchain - develop for Android devices (Android SDK version 34.0.0)
    • Android SDK at /path/to/Android/Sdk
    • Platform android-34, build-tools 34.0.0
    • Java binary at: /path/to/java
    • Java version OpenJDK Runtime Environment (build 11.0.x)
    • All Android licenses accepted.
```

## 📱 Create Android Virtual Device (AVD)

### Step 1: Open AVD Manager
1. **Open Android Studio**
2. **Click**: Tools → AVD Manager
3. **Click**: "Create Virtual Device"

### Step 2: Choose Device
**Recommended devices**:
- **Pixel 7 Pro** (Large screen, latest features)
- **Pixel 6** (Good balance of features and performance)
- **Nexus 5X** (Older device testing)

### Step 3: Choose System Image
**Recommended**:
- **API Level 34** (Android 14) - Latest
- **API Level 33** (Android 13) - Stable
- **API Level 30** (Android 11) - Wide compatibility

**Choose**:
- ✅ **x86_64** (Intel/AMD processors)
- ✅ **Google APIs** (for Google services)
- ✅ **Google Play** (for Play Store testing)

### Step 4: Configure AVD
- **AVD Name**: `Pixel_7_Pro_API_34`
- **Startup Orientation**: Portrait
- **Advanced Settings**:
  - **RAM**: 4096 MB (minimum for smooth performance)
  - **VM Heap**: 512 MB
  - **Internal Storage**: 8 GB
  - **SD Card**: 1 GB (optional)

## 🔧 Project-Specific Configuration

### build.gradle.kts (App Level)
```kotlin
android {
    namespace = "com.example.student_reminder_app"
    compileSdk = 34
    
    defaultConfig {
        applicationId = "com.example.student_reminder_app"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = "11"
    }
}
```

### Permissions (android/app/src/main/AndroidManifest.xml)
```xml
<!-- Internet permission for Firebase -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- Notification permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Wake lock for notifications -->
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Boot receiver for scheduled notifications -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- Optional: Camera for profile pictures -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Optional: Storage for file attachments -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 🚀 Build Commands

### Debug Build
```bash
cd student_reminder_app
flutter build apk --debug
```

### Release Build
```bash
cd student_reminder_app
flutter build apk --release
```

### Install on Device/Emulator
```bash
flutter install
```

### Run on Specific Device
```bash
flutter devices                    # List available devices
flutter run -d <device_id>        # Run on specific device
```

## 🔍 Troubleshooting

### Common Issues:

#### 1. "No Android SDK found"
**Solution**:
```bash
# Check ANDROID_HOME
echo $ANDROID_HOME  # macOS/Linux
echo %ANDROID_HOME% # Windows

# If empty, set it:
export ANDROID_HOME=/path/to/Android/Sdk
```

#### 2. "Android license status unknown"
**Solution**:
```bash
flutter doctor --android-licenses
# Accept all licenses
```

#### 3. "Gradle build failed"
**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### 4. "Unable to locate adb"
**Solution**:
```bash
# Add platform-tools to PATH
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

#### 5. "Emulator not starting"
**Solutions**:
- Enable **Virtualization** in BIOS
- Install **Intel HAXM** or **AMD Hypervisor**
- Increase **RAM allocation** for AVD
- Use **Cold Boot** instead of Quick Boot

### Performance Tips:

#### For Development:
- Use **x86_64 emulator** (faster than ARM)
- Enable **Hardware Acceleration**
- Allocate **sufficient RAM** (4GB+)
- Use **SSD storage** for Android SDK
- Close **unnecessary applications**

#### For Testing:
- Test on **real devices** when possible
- Use **different API levels** (21, 30, 34)
- Test on **different screen sizes**
- Test with **different Android versions**

## 📋 Build Verification Checklist

Before releasing:
- [ ] App builds successfully with `flutter build apk --release`
- [ ] App installs on physical device
- [ ] App runs on Android 5.0 (API 21) minimum
- [ ] App runs on Android 14 (API 34) target
- [ ] Firebase services work correctly
- [ ] Notifications work on device
- [ ] Google Sign-In works
- [ ] Offline functionality works
- [ ] App follows Material Design guidelines
- [ ] App passes `flutter analyze` without errors
- [ ] All tests pass with `flutter test`

## 🔐 Signing for Release

### Generate Keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Configure Signing:
Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>
```

### Update build.gradle.kts:
```kotlin
android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

---

**Note**: Keep your keystore file secure and never commit it to version control. The keystore is required for all future app updates on Google Play Store.