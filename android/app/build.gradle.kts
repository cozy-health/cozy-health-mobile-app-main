import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.isFile) propertiesFile.inputStream().use { load(it) }
}
val dartDefines = providers.gradleProperty("dart-defines").orNull
    ?.split(",")?.filter { it.isNotBlank() }?.associate { encoded ->
        val entry = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        val separator = entry.indexOf('=')
        require(separator > 0) { "Invalid Dart build definition" }
        entry.substring(0, separator) to entry.substring(separator + 1)
    } ?: emptyMap()
val productionBuild = dartDefines["COZY_ENVIRONMENT"] == "production"
val releaseApplicationId = providers.environmentVariable("COZY_ANDROID_APPLICATION_ID").orNull
    ?: "com.example.cozy_health"
val signingKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val releaseSigningReady = signingKeys.all { !releaseProperties.getProperty(it).isNullOrBlank() }

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

android {
    namespace = "com.example.cozy_health"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = if (productionBuild) releaseApplicationId else "com.example.cozy_health"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseSigningReady) {
            create("release") {
                storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = if (productionBuild) signingConfigs.findByName("release")
                else signingConfigs.getByName("debug")
        }
    }
}

val validateProductionRelease by tasks.registering {
    doLast {
        if (productionBuild) {
            check(!releaseApplicationId.startsWith("com.example.") &&
                Regex("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+").matches(releaseApplicationId)) {
                "Set COZY_ANDROID_APPLICATION_ID to the registered production application ID."
            }
            check(dartDefines["INTERNAL_TEST_BUILD"] != "true" && dartDefines["COZY_DEMO"] != "true") {
                "Production releases cannot enable internal testing or demo mode."
            }
            check(releaseSigningReady) { "Configure all four signing values in android/key.properties." }
            check(rootProject.file(releaseProperties.getProperty("storeFile")).isFile) {
                "The production upload keystore does not exist."
            }
            val currentPin = dartDefines["API_CURRENT_LEAF_SHA256"]?.lowercase().orEmpty()
            val nextPin = dartDefines["API_NEXT_LEAF_SHA256"]?.lowercase().orEmpty()
            check(Regex("[a-f0-9]{64}").matches(currentPin) &&
                Regex("[a-f0-9]{64}").matches(nextPin) && currentPin != nextPin) {
                "Supply two distinct, independently verified production certificate fingerprints."
            }
        }
    }
}
tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateProductionRelease)
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
