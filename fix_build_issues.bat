@echo off
echo Fixing build issues for Student Reminder App...

echo 1. Cleaning Flutter project...
flutter clean

echo 2. Getting packages...
flutter pub get

echo 3. Building APK...
flutter build apk

echo Build process completed. Check for any remaining errors above.
pause