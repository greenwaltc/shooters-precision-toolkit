import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val uploadSigning = Properties()
val uploadSigningFile = rootProject.file("key.properties")
if (uploadSigningFile.exists()) uploadSigningFile.inputStream().use { uploadSigning.load(it) }

android {
    namespace = "com.bramwell.bramwells_precision_test_kit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bramwell.bramwells_precision_test_kit"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Precision Test Kit Dev")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Precision Test Kit")
        }
    }

    signingConfigs {
        if (uploadSigningFile.exists()) {
            create("upload") {
                keyAlias = uploadSigning.getProperty("keyAlias")
                keyPassword = uploadSigning.getProperty("keyPassword")
                storeFile = rootProject.file(uploadSigning.getProperty("storeFile"))
                storePassword = uploadSigning.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (uploadSigningFile.exists()) "upload" else "debug")
        }
    }
}

// Never distribute a production release signed with the debug key.
gradle.taskGraph.whenReady {
    if (!uploadSigningFile.exists() && allTasks.any { it.name.contains("ProdRelease", ignoreCase = true) }) {
        throw GradleException("Production release signing requires android/key.properties; see key.properties.example.")
    }
}

flutter {
    source = "../.."
}
