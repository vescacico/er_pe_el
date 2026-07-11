plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase services
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.fittask"
    compileSdk = 36  // ← UBAH dari 34 menjadi 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.fittask"
        minSdk = flutter.minSdkVersion  // minimal 23 untuk Google Sign-In
        targetSdk = 36  // ← UBAH juga targetSdk ke 36

        // ============================================================
        // PENTING: Agar aplikasi ter-UPDATE bukan Fresh Install:
        // - JANGAN ubah versionCode dan versionName ini
        // - Gunakan keystore yang SAMA untuk signing
        // - Jika ingin upgrade, increment versionCode saja
        // ============================================================
        versionCode = 1  // INCREMENT INI untuk update (1 -> 2 -> 3, dst)
        versionName = "1.0.0"  // Ubah sesuai versi (opsional)

        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
        debug {
            // Pastikan debug build juga menggunakan signing yang konsisten
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ============================================================
    // INSTRUKSI PENTING UNTUK UPDATE:
    // 1. Generate keystore pertama kali dengan command:
    //    keytool -genkey -v -keystore ~/.android/debug.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000
    //
    // 2. Atau buat keystore khusus dengan command:
    //    keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fittask
    //
    // 3. Untuk release build dengan keystore khusus, tambahkan konfigurasi:
    //    signingConfig signingConfigs.debug  // atau custom keystore
    //
    // 4. SIMPAN keystore dengan AMAN - dibutuhkan untuk update berikutnya!
    // ============================================================
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
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}
