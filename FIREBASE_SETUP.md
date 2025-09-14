# Firebase Setup Guide for Student Reminder App

## 🔥 Firebase Console Configuration

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project" or "Add project"
3. Enter project name: `student-reminder-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Choose or create a Google Analytics account
6. Click "Create project"

### Step 2: Add Android App
1. In Firebase Console, click "Add app" → Android icon
2. **Android package name**: `com.example.student_reminder_app`
3. **App nickname**: `Student Reminder Android`
4. **Debug signing certificate SHA-1**: (Optional for development)
   - Get SHA-1: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
5. Click "Register app"
6. **Download `google-services.json`**
7. Place file in: `android/app/google-services.json`

### Step 3: Add iOS App
1. In Firebase Console, click "Add app" → iOS icon
2. **iOS bundle ID**: `com.example.studentReminderApp`
3. **App nickname**: `Student Reminder iOS`
4. **App Store ID**: (Leave empty for development)
5. Click "Register app"
6. **Download `GoogleService-Info.plist`**
7. Place file in: `ios/Runner/GoogleService-Info.plist`

### Step 4: Add Web App
1. In Firebase Console, click "Add app" → Web icon
2. **App nickname**: `Student Reminder Web`
3. **Enable Firebase Hosting**: ✅ (Optional)
4. Click "Register app"
5. Copy the Firebase configuration object
6. Update `lib/firebase_options.dart` with the web configuration

## 🔧 Firebase Services to Enable

### 1. Authentication
**Location**: Firebase Console → Authentication → Sign-in method

**Enable these providers**:
- ✅ **Email/Password**
  - Enable "Email/Password"
  - Enable "Email link (passwordless sign-in)" (Optional)
- ✅ **Google**
  - Enable Google sign-in
  - Set project support email
  - Download updated config files after enabling

**Settings to configure**:
- **Authorized domains**: Add your domains (localhost is included by default)
- **User actions**: Configure email templates (Optional)
- **Advanced**: Set up password policy (Optional)

### 2. Firestore Database
**Location**: Firebase Console → Firestore Database

**Setup**:
1. Click "Create database"
2. **Security rules**: Start in test mode (change to production rules later)
3. **Location**: Choose closest region to your users
4. Click "Done"

**Collections to create** (will be created automatically by the app):
- `users` - User profile data
- `reminders` - User reminders and tasks

**Security Rules** (update after testing):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can only access their own reminders
    match /reminders/{reminderId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### 3. Cloud Messaging (FCM)
**Location**: Firebase Console → Cloud Messaging

**Setup**:
1. **Server key**: Copy for backend use (if needed)
2. **Sender ID**: Already configured in app
3. **APNs Authentication Key**: Upload for iOS push notifications
   - Generate APNs key in Apple Developer Console
   - Upload .p8 file to Firebase
   - Enter Key ID and Team ID

**Topics to create** (Optional):
- `all_users` - Broadcast messages
- `reminders` - Reminder-specific notifications

### 4. Storage (Optional - for future features)
**Location**: Firebase Console → Storage

**Setup**:
1. Click "Get started"
2. **Security rules**: Start in test mode
3. **Location**: Same as Firestore
4. Click "Done"

**Use cases**:
- User profile pictures
- Attachment files for reminders
- App assets and resources

### 5. Analytics (Already enabled)
**Location**: Firebase Console → Analytics

**Events to track**:
- `reminder_created`
- `reminder_completed`
- `user_login`
- `notification_opened`

## 🔑 Configuration Files to Update

### 1. `lib/firebase_options.dart`
Replace the mock values with your actual Firebase project configuration:

```dart
// Replace these with your actual Firebase project values
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',
  appId: 'YOUR_ANDROID_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  storageBucket: 'your-project-id.appspot.com',
  iosBundleId: 'com.example.studentReminderApp',
);

static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_WEB_API_KEY',
  appId: 'YOUR_WEB_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  storageBucket: 'your-project-id.appspot.com',
  measurementId: 'YOUR_MEASUREMENT_ID',
);
```

### 2. `android/app/google-services.json`
Replace the entire file with the one downloaded from Firebase Console.

### 3. `ios/Runner/GoogleService-Info.plist`
Replace the entire file with the one downloaded from Firebase Console.

## 🧪 Testing Firebase Integration

### 1. Authentication Test
```dart
// Test Google Sign-In
final user = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
print('Signed in: ${user.user?.displayName}');

// Test Email Sign-In
final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
  email: 'test@example.com',
  password: 'password123',
);
print('Signed in: ${credential.user?.email}');
```

### 2. Firestore Test
```dart
// Test writing data
await FirebaseFirestore.instance.collection('test').add({
  'message': 'Hello Firebase!',
  'timestamp': FieldValue.serverTimestamp(),
});

// Test reading data
final snapshot = await FirebaseFirestore.instance.collection('test').get();
print('Documents: ${snapshot.docs.length}');
```

### 3. FCM Test
```dart
// Get FCM token
final token = await FirebaseMessaging.instance.getToken();
print('FCM Token: $token');

// Test notification permission
final settings = await FirebaseMessaging.instance.requestPermission();
print('Permission: ${settings.authorizationStatus}');
```

## 🚀 Deployment Checklist

### Before Production:
- [ ] Update Firestore security rules
- [ ] Configure proper authentication domains
- [ ] Set up APNs certificates for iOS
- [ ] Configure FCM server key for backend
- [ ] Enable Firebase App Check (security)
- [ ] Set up Firebase Performance Monitoring
- [ ] Configure Analytics conversion events
- [ ] Test all authentication flows
- [ ] Test offline/online sync
- [ ] Test push notifications on real devices

### Security Best Practices:
- [ ] Never commit actual config files to public repos
- [ ] Use environment variables for sensitive keys
- [ ] Implement proper Firestore security rules
- [ ] Enable Firebase App Check
- [ ] Use Firebase Auth custom claims for roles
- [ ] Implement rate limiting for API calls
- [ ] Monitor Firebase usage and costs

## 📱 Platform-Specific Notes

### Android:
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Google Play Services required for FCM
- ProGuard rules may be needed for release builds

### iOS:
- Minimum iOS: 12.0
- APNs certificate required for push notifications
- Background app refresh needed for FCM
- Xcode project configuration required

### Web:
- HTTPS required for FCM
- Service worker needed for background notifications
- Firebase Hosting recommended for deployment

## 🔍 Troubleshooting

### Common Issues:
1. **"Default FirebaseApp is not initialized"**
   - Ensure `Firebase.initializeApp()` is called before any Firebase usage
   - Check that config files are in correct locations

2. **Google Sign-In not working**
   - Verify SHA-1 fingerprint is added to Firebase Console
   - Check that `google-services.json` is up to date
   - Ensure Google Sign-In is enabled in Firebase Console

3. **FCM not receiving notifications**
   - Check notification permissions are granted
   - Verify FCM token is generated
   - Test with Firebase Console notification composer
   - Check device is not in Do Not Disturb mode

4. **Firestore permission denied**
   - Check security rules allow the operation
   - Verify user is authenticated
   - Ensure document path matches security rules

### Debug Commands:
```bash
# Check Firebase CLI
firebase --version

# Login to Firebase
firebase login

# List Firebase projects
firebase projects:list

# Check Firestore indexes
firebase firestore:indexes

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

---

**Note**: Replace all placeholder values with your actual Firebase project configuration. Keep your API keys and configuration files secure and never commit them to public repositories.