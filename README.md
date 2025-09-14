# Student Reminder & Calendar App

A cross-platform Flutter application designed for students to manage their academic reminders, deadlines, and calendar events with modern UI, Firebase integration, and offline support.

## 🚀 Features

### ✅ Implemented
- **Clean Architecture** with separation of concerns (UI, Business Logic, Data)
- **Material 3 Design** with soft pastel colors (green/blue/white theme)
- **State Management** using Riverpod
- **Local Storage** with Hive for offline functionality
- **Firebase Integration** ready (Authentication, Firestore, FCM)
- **Notification System** (Local notifications + Push notifications)
- **Comprehensive Testing** (39 unit tests passing)

### 🔄 In Progress
- Bottom navigation with 3 tabs (Calendar, Reminders, Settings)
- Calendar view (monthly/weekly) with reminder markers
- Reminder CRUD operations with smooth animations
- Authentication screens (Google Sign-In, Email/Password)
- Settings screen with theme toggle

### 📋 Planned
- Offline synchronization with conflict resolution
- Recurring reminders (daily, weekly, monthly, yearly)
- Swipe gestures for reminder actions
- Hero animations and micro-interactions
- Performance optimizations

## 🏗️ Architecture

```
lib/
├── app/                    # App-level configuration
│   └── theme/             # Material 3 themes
├── core/                  # Core utilities and constants
│   ├── constants/         # App constants
│   ├── errors/           # Custom exceptions
│   ├── models/           # Shared models (OfflineAction)
│   └── utils/            # Utility functions (date, validation)
├── features/             # Feature-based modules
│   ├── auth/             # Authentication feature
│   ├── calendar/         # Calendar feature
│   ├── reminders/        # Reminders feature
│   └── settings/         # Settings feature
└── shared/               # Shared components
    ├── providers/        # Riverpod providers
    ├── services/         # Business logic services
    └── widgets/          # Reusable widgets
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.35.3
- **State Management**: Riverpod 2.6.1
- **Local Database**: Hive 2.2.3
- **Backend**: Firebase (Auth, Firestore, FCM)
- **Navigation**: GoRouter 12.1.3
- **UI Components**: Material 3
- **Notifications**: flutter_local_notifications + FCM
- **Testing**: flutter_test with comprehensive unit tests

## 📱 Setup Instructions

### Prerequisites
1. **Flutter SDK** (3.0 or higher)
2. **Android Studio** (for Android development)
3. **Xcode** (for iOS development, macOS only)
4. **Firebase Project** (for cloud features)

### Installation

1. **Clone and setup**:
   ```bash
   cd student_reminder_app
   flutter pub get
   ```

2. **Firebase Configuration**:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Google Sign-In, Email/Password)
   - Enable Firestore Database
   - Enable Cloud Messaging
   - Replace the mock configuration files:
     - `lib/firebase_options.dart`
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

5. **Build APK** (requires Android SDK):
   ```bash
   flutter build apk
   ```

### Android SDK Setup
If you get "No Android SDK found" error:

1. **Install Android Studio**
2. **Set environment variables**:
   ```bash
   # Windows
   set ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk
   set PATH=%PATH%;%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools
   
   # macOS/Linux
   export ANDROID_HOME=$HOME/Library/Android/sdk
   export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
   ```
3. **Accept licenses**:
   ```bash
   flutter doctor --android-licenses
   ```

## 🧪 Testing

The app includes comprehensive unit tests covering:

- **Data Models**: Reminder, User, OfflineAction serialization
- **Local Storage**: Hive CRUD operations, offline queue management
- **Firebase Service**: Authentication, Firestore operations (mocked)
- **Notification Service**: Local and push notification scheduling (mocked)

Run tests with:
```bash
flutter test
```

Current test coverage: **39 tests passing**

## 🎨 Design System

### Color Palette
- **Primary**: Soft Green (#4CAF50)
- **Secondary**: Soft Blue (#2196F3)
- **Background**: White/Dark Grey
- **Surface**: Light Grey/Dark Surface
- **Accent**: Pastel variants

### Typography
- Material 3 typography scale
- Consistent text sizing and weights
- Accessibility-compliant contrast ratios

### Components
- Rounded cards (12px border radius)
- Elevated buttons with soft shadows
- Input fields with filled style
- Bottom navigation with proper theming

## 📊 Current Status

### Completed Tasks (5/18)
✅ Project foundation and dependencies  
✅ Core data models and utilities  
✅ Local storage infrastructure  
✅ Firebase integration services  
✅ Notification system  

### Next Tasks
🔄 State management with Riverpod providers  
🔄 App theme and styling system  
🔄 Authentication screens and flow  
🔄 Main navigation structure  
🔄 Calendar screen and functionality  

## 🤝 Contributing

This is a demo project showcasing Flutter best practices for student reminder apps. The codebase demonstrates:

- Clean Architecture principles
- Comprehensive error handling
- Offline-first approach with sync
- Modern Flutter development patterns
- Extensive testing strategies

## 📄 License

This project is for educational and demonstration purposes.

---

**Note**: This app is currently in development. Firebase configuration files contain mock data and should be replaced with actual Firebase project credentials for production use.