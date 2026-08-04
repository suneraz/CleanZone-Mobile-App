// Add buildscript block for plugin dependencies
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4") // Match your Gradle version
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0") // Match your Kotlin version
        classpath("com.google.gms:google-services:4.4.2") // For FlutterFire
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Enforce Java 11 for all subprojects
    tasks.withType<JavaCompile> {
        sourceCompatibility = JavaVersion.VERSION_11.toString()
        targetCompatibility = JavaVersion.VERSION_11.toString()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
