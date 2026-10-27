import java.util.Properties

plugins {
    id("com.android.application")
    // Kotlin is applied by the Flutter Gradle Plugin (android.builtInKotlin=false).
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing key, written by CI from repository secrets (see
// .github/workflows/build-apk.yml). Every APK must carry the same key, or
// Android refuses to install it over the previous one.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

// A release must update the existing installation with its established key.
// Debug builds remain available without private signing material.
gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { it.project == project && it.name.endsWith("Release") }
    if (buildsRelease) {
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        if (required.any { keystoreProperties.getProperty(it).isNullOrBlank() }) {
            throw GradleException("Release signing is incomplete. Configure the existing Wallet key in android/key.properties; do not replace it with a debug key.")
        }
        if (!file(keystoreProperties.getProperty("storeFile")).isFile) {
            throw GradleException("Wallet release keystore is unavailable. Restore the existing private signing backup before building a release.")
        }
    }
}

android {
    namespace = "com.example.financial_recording"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.irsyads.wallet"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystoreProperties.containsKey("storeFile")) {
            create("release") {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
