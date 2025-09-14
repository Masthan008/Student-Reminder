plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services plugin for Firebase (temporarily disabled for initial build)
    // id("com.google.gms.google-services")
}

android {
    namespace = "com.example.student_reminder_app"
    compileSdk = 36  // Updated to support latest plugins
    ndkVersion = "27.0.12077973"  // Updated to support Firebase plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID for Student Reminder App
        applicationId = "com.example.student_reminder_app"
        
        // SDK Versions
        minSdk = flutter.minSdkVersion      // Android 5.0 (API level 21) - Required for Firebase
        targetSdk = 34   // Android 14 (API level 34) - Latest stable
        
        // App Version
        versionCode = 1
        versionName = "1.0.0"
        
        // Multidex support for Firebase
        multiDexEnabled = true
        
        // Test instrumentation runner
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
