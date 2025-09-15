@echo off
echo Complete fix for Student Reminder App build issues...

echo 1. Cleaning Flutter project...
flutter clean

echo 2. Cleaning Android build cache...
cd android
if exist build rmdir /s /q build
if exist .gradle rmdir /s /q .gradle
cd ..

echo 3. Removing pubspec.lock to force dependency resolution...
del pubspec.lock

echo 4. Getting packages...
flutter pub get

echo 5. Running build runner to generate necessary files...
dart run build_runner build --delete-conflicting-outputs

echo 6. Building APK with verbose output...
flutter build apk --verbose

echo Complete fix process finished. Check for any remaining errors above.
pause