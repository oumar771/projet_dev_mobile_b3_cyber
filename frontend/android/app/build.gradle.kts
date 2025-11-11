plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.frontend"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // 👇 Ajout pour forcer la génération d’APK et éviter les splits inutiles
    bundle {
        abi.enableSplit = false
        density.enableSplit = false
        language.enableSplit = false
    }

    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            // 👇 Ajout pour éviter certains conflits de packaging
            packagingOptions {
                resources.excludes.add("META-INF/*")
            }
        }

        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // 👇 Ajout pour éviter certains conflits de packaging
            packagingOptions {
                resources.excludes.add("META-INF/*")
            }
            // signingConfig = signingConfigs.getByName("release") // configure ton keystore si nécessaire
        }
    }

    // Optionnel : viewBinding / dataBinding si besoin
    // buildFeatures {
    //     viewBinding = true
    // }
}

flutter {
    source = "../.."
}
