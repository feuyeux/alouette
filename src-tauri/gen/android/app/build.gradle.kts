import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("rust")
}

val tauriProperties = Properties().apply {
    val propFile = file("tauri.properties")
    if (propFile.exists()) {
        propFile.inputStream().use { load(it) }
    }
}

android {
    compileSdk = 34
    namespace = "com.alouette.app"
    defaultConfig {
        manifestPlaceholders["usesCleartextTraffic"] = "false"
        applicationId = "com.alouette.app"
        minSdk = 24
        targetSdk = 34
        versionCode = tauriProperties.getProperty("tauri.android.versionCode", "1").toInt()
        versionName = tauriProperties.getProperty("tauri.android.versionName", "1.0")
        
        // 添加NDK配置以支持C++标准库
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64"))
        }
    }
    buildTypes {
        getByName("debug") {
            manifestPlaceholders["usesCleartextTraffic"] = "true"
            isDebuggable = true
            isJniDebuggable = true
            isMinifyEnabled = false
        }
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(
                *fileTree(".") { include("**/*.pro") }
                    .plus(getDefaultProguardFile("proguard-android-optimize.txt"))
                    .toList().toTypedArray()
            )
        }
    }
    
    packaging {
        jniLibs {
            keepDebugSymbols.add("*/arm64-v8a/*.so")
            keepDebugSymbols.add("*/armeabi-v7a/*.so") 
            keepDebugSymbols.add("*/x86/*.so")
            keepDebugSymbols.add("*/x86_64/*.so")
            
            // 确保包含C++共享库
            pickFirsts.add("**/libc++_shared.so")
            pickFirsts.add("**/libunwind.so")
            pickFirsts.add("**/libatomic.so")
        }
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        buildConfig = true
    }
    
    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }
    
    // 确保C++标准库被包含
    packagingOptions {
        pickFirst("**/libc++_shared.so")
        pickFirst("**/libunwind.so") 
    }
}

// 强制使用兼容的 Jackson 版本
configurations.all {
    resolutionStrategy {
        force("com.fasterxml.jackson.core:jackson-core:2.13.4")
        force("com.fasterxml.jackson.core:jackson-databind:2.13.4")
        force("com.fasterxml.jackson.core:jackson-annotations:2.13.4")
    }
}

rust {
    rootDirRel = "../../../"
}

// 添加任务来复制NDK的C++标准库
task("copyNdkLibs") {
    doLast {
        val ndkPath = System.getenv("NDK_HOME") ?: "${System.getenv("ANDROID_HOME")}/ndk/android-ndk-r28b"
        val libsDir = file("src/main/jniLibs")
        
        listOf("arm64-v8a", "armeabi-v7a", "x86", "x86_64").forEach { abi ->
            val targetDir = file("$libsDir/$abi")
            targetDir.mkdirs()
            
            val arch = when(abi) {
                "arm64-v8a" -> "aarch64-linux-android"
                "armeabi-v7a" -> "arm-linux-androideabi" 
                "x86" -> "i686-linux-android"
                "x86_64" -> "x86_64-linux-android"
                else -> abi
            }
            
            val sourceLib = file("$ndkPath/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/$arch/libc++_shared.so")
            val targetLib = file("$targetDir/libc++_shared.so")
            
            if (sourceLib.exists()) {
                sourceLib.copyTo(targetLib, overwrite = true)
                println("Copied libc++_shared.so for $abi")
            }
        }
    }
}

// 确保在构建之前复制库
tasks.getByName("preBuild").dependsOn("copyNdkLibs")

dependencies {
    implementation("androidx.webkit:webkit:1.6.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.8.0")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.4")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.0")
}

apply(from = "tauri.build.gradle.kts")