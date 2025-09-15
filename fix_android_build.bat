@echo off
echo Fixing Android build issues for Student Reminder App...

echo 1. Cleaning Flutter project...
flutter clean

echo 2. Cleaning Android build cache...
cd android
if exist build rmdir /s /q build
if exist .gradle rmdir /s /q .gradle
cd ..

echo 3. Getting packages...
flutter pub get

echo 4. Running build runner to generate necessary files...
dart run build_runner build --delete-conflicting-outputs

echo 5. Building APK...
flutter build apk

echo Android build process completed. Check for any remaining errors above.
pause