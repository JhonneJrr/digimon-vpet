plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.digimon.vpet.digimon"
    compileSdk = flutter.compileSdkVersion
    // This app has no native C/C++ code, so it does not need the Android NDK.
    // The default flutter.ndkVersion pointed at an NDK that isn't installed,
    // making AGP try to auto-provision a ~2.4GB NDK on every build. Omit it so
    // AGP only requires the NDK when a task genuinely needs native tooling.
    // ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications (uses java.time APIs).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.digimon.vpet.digimon"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signing with the debug keys so the app installs on any device
            // (fine for personal/sideload builds; not for Play Store).
            signingConfig = signingConfigs.getByName("debug")

            // Disable R8 code shrinking/obfuscation for release. WorkManager
            // (via the workmanager plugin) instantiates androidx.work's Room
            // database `WorkDatabase_Impl` by REFLECTION at startup; R8 was
            // stripping/renaming it, so the app crashed on launch with
            // `NoSuchMethodException: WorkDatabase_Impl.<init>`. Turning
            // shrinking off removes that whole class of reflection-strip
            // crashes (also protects flutter_local_notifications' Gson use).
            // The app is tiny, so the size cost is negligible.
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Backports java.time etc. for older Android; required by
    // flutter_local_notifications with core library desugaring enabled.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
