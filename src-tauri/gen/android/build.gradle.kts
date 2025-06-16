buildscript {
    repositories {
        // 优先使用华为云镜像
        maven("https://repo.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/gradle-plugin")
        maven("https://maven.aliyun.com/repository/public")
        // 备用官方仓库
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.25")
    }
}

allprojects {
    repositories {
        // 优先使用华为云镜像
        maven("https://repo.huaweicloud.com/repository/maven/")
        maven("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/")
        maven("https://maven.aliyun.com/repository/google")
        maven("https://maven.aliyun.com/repository/central")
        maven("https://maven.aliyun.com/repository/public")
        // 备用官方仓库
        google()
        mavenCentral()
    }
    
    // 全局强制使用兼容的 Jackson 版本
    configurations.all {
        resolutionStrategy {
            force("com.fasterxml.jackson.core:jackson-core:2.13.4")
            force("com.fasterxml.jackson.core:jackson-databind:2.13.4") 
            force("com.fasterxml.jackson.core:jackson-annotations:2.13.4")
        }
    }
}

tasks.register("clean").configure {
    delete("build")
}

