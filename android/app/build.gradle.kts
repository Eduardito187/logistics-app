import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Firma de release. `android/key.properties` (gitignored) apunta al keystore de
// subida, que vive FUERA de git (android/keystore/, también ignorado). En CI se
// reconstruyen ambos desde secrets (ver docs/release.md). Sin key.properties se
// cae a la clave de debug con un aviso, para no romper builds locales ni el CI
// de PRs; con REQUIRE_RELEASE_SIGNING=true (job de release) falta = error.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseKeystore = keystorePropertiesFile.exists()
val requireReleaseSigning = System.getenv("REQUIRE_RELEASE_SIGNING") == "true"

android {
    namespace = "bo.com.dismac.logistics_app"
    // Fijos: Flutter 3.32 trae SDK 35 / NDK 26, pero los plugins compilan contra
    // SDK 36 y NDK 27 (ambos retrocompatibles).
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requerido por flutter_local_notifications (y plugins que usan APIs
        // java.time en minSdk bajo). Habilita el desugaring de la librería core.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // ID definitivo de la app interna (no cambiar: identifica la app en
        // Managed Google Play/MDM y en Firebase; cambiarlo = app nueva).
        applicationId = "bo.com.dismac.logistics_app"
        // Fijo en 24 (el default de Flutter 3.47): Flutter 3.32 trae 21 y
        // flutter_secure_storage exige >= 23.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // versionName/versionCode salen de `version:` en pubspec.yaml (x.y.z+N).
        // Con --split-per-abi Flutter suma 1000 * ABI al versionCode
        // (armeabi-v7a=1xxx, arm64-v8a=2xxx, x86_64=4xxx) para que cada APK
        // tenga su propio código; siempre subir N en pubspec al publicar.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else if (requireReleaseSigning) {
                throw GradleException(
                    "REQUIRE_RELEASE_SIGNING=true pero falta android/key.properties " +
                        "(ver docs/release.md).",
                )
            } else {
                logger.warn(
                    "AVISO: no existe android/key.properties; el release se firma con " +
                        "la clave de DEBUG (no sirve para distribuir). Ver docs/release.md.",
                )
                signingConfigs.getByName("debug")
            }

            // Gama baja (1 GB de RAM): R8 quita y ofusca el código Java/Kotlin
            // de los plugins que no se usa (menos DEX que cargar en memoria) y
            // shrinkResources descarta recursos sin referencia. Reglas propias
            // en proguard-rules.pro; recursos usados por nombre en
            // res/raw/keep.xml. Ver docs/rendimiento-y-pantallas.md.
            isMinifyEnabled = true
            isShrinkResources = true
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

dependencies {
    // Desugaring de la librería core para flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
