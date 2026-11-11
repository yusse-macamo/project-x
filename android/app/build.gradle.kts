import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Chave de assinatura de produção, fora do git (ver android/key.properties.exemplo).
// Sem ela, as compilações de release são assinadas com a chave de debug e não
// podem ser publicadas na Play Store.
val propriedadesChave = Properties()
val ficheiroChave = rootProject.file("key.properties")
val temChaveRelease = ficheiroChave.exists()
if (temChaveRelease) {
    FileInputStream(ficheiroChave).use { propriedadesChave.load(it) }
}

android {
    namespace = "mz.rota"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Uma só app: passageiro e motorista escolhem-se dentro dela.
    //   flutter run --flavor passageiro --dart-define-from-file=env/dev.json
    // O flavor mantém o id já instalado (mz.rota.passageiro).
    flavorDimensions += "app"
    productFlavors {
        create("passageiro") {
            dimension = "app"
            applicationId = "mz.rota.passageiro"
            manifestPlaceholders["nomeApp"] = "ROTA"
        }
    }

    signingConfigs {
        if (temChaveRelease) {
            create("release") {
                keyAlias = propriedadesChave["keyAlias"] as String
                keyPassword = propriedadesChave["keyPassword"] as String
                storeFile = file(propriedadesChave["storeFile"] as String)
                storePassword = propriedadesChave["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temChaveRelease) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
