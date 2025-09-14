# Quick Command Reference

## 📁 **IMPORTANT: Always run commands from the project directory!**

```bash
# Navigate to project directory first
cd student_reminder_app

# Then run Flutter commands
```

## 🔍 **Verification Commands**

### Check Flutter Setup
```bash
cd student_reminder_app
flutter doctor -v
```

### Check Code Quality
```bash
cd student_reminder_app
flutter analyze
```

### Run Tests
```bash
cd student_reminder_app
flutter test
```

### Check Dependencies
```bash
cd student_reminder_app
flutter pub get
flutter pub deps
```

## 🏗️ **Build Commands**

### Debug Build (requires Android SDK)
```bash
cd student_reminder_app
flutter build apk --debug
```

### Release Build (requires Android SDK + signing)
```bash
cd student_reminder_app
flutter build apk --release
```

### Web Build
```bash
cd student_reminder_app
flutter build web
```

## 📱 **Run Commands**

### Run on Connected Device/Emulator
```bash
cd student_reminder_app
flutter run
```

### Run in Debug Mode
```bash
cd student_reminder_app
flutter run --debug
```

### Run in Release Mode
```bash
cd student_reminder_app
flutter run --release
```

### List Available Devices
```bash
cd student_reminder_app
flutter devices
```

### Run on Specific Device
```bash
cd student_reminder_app
flutter run -d <device_id>
```

## 🛠️ **Development Commands**

### Clean Project
```bash
cd student_reminder_app
flutter clean
flutter pub get
```

### Generate Code (for Hive adapters)
```bash
cd student_reminder_app
flutter packages pub run build_runner build
```

### Watch for Changes (auto-generate)
```bash
cd student_reminder_app
flutter packages pub run build_runner watch
```

## 🔧 **Android SDK Setup Commands**

### Check Android Setup
```bash
flutter doctor --android-licenses
```

### Accept All Licenses
```bash
flutter doctor --android-licenses
# Type 'y' for all prompts
```

### Set Environment Variables (Windows)
```cmd
# Set ANDROID_HOME (replace with your actual path)
setx ANDROID_HOME "C:\Users\%USERNAME%\AppData\Local\Android\Sdk"

# Add to PATH
setx PATH "%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools"
```

### Set Environment Variables (macOS/Linux)
```bash
# Add to ~/.bashrc or ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# export ANDROID_HOME=$HOME/Android/Sdk        # Linux

export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

## 🚨 **Common Error Solutions**

### "No pubspec.yaml file found"
**Problem**: Running Flutter commands from wrong directory
**Solution**: 
```bash
cd student_reminder_app  # Navigate to project directory first
flutter <command>
```

### "No Android SDK found"
**Problem**: Android SDK not installed or ANDROID_HOME not set
**Solution**: 
1. Install Android Studio
2. Set ANDROID_HOME environment variable
3. Run `flutter doctor --android-licenses`

### "Gradle build failed"
**Solution**:
```bash
cd student_reminder_app
flutter clean
flutter pub get
flutter build apk --debug
```

### "Firebase not initialized"
**Problem**: Mock Firebase config files
**Solution**: Replace with actual Firebase project configuration

## 📊 **Current Project Status**

### ✅ Working Commands (no Android SDK needed):
```bash
cd student_reminder_app
flutter analyze          # ✅ Works (6 minor style suggestions)
flutter test            # ✅ Works (39 tests passing)
flutter pub get         # ✅ Works
flutter clean           # ✅ Works
```

### ⚠️ Requires Android SDK Setup:
```bash
cd student_reminder_app
flutter build apk       # ❌ Needs Android SDK
flutter run             # ❌ Needs Android SDK or emulator
flutter devices         # ❌ Needs Android SDK
```

### ⚠️ Requires Firebase Configuration:
```bash
# App will run but Firebase features won't work until you:
# 1. Create actual Firebase project
# 2. Replace mock config files
# 3. Enable Firebase services
```

## 🎯 **Next Steps Priority**

1. **Set up Android SDK** (see ANDROID_SDK_SETUP.md)
2. **Create Firebase project** (see FIREBASE_SETUP.md)
3. **Test build**: `flutter build apk --debug`
4. **Continue development** with UI implementation

## 💡 **Pro Tips**

- Always `cd student_reminder_app` first
- Use `flutter doctor -v` to diagnose issues
- Keep terminal open in project directory
- Use `flutter clean` when things get weird
- Test on real devices when possible