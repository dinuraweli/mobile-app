// File: android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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

subprojects {
    val patchNamespace = {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(androidExt) as? String
                
                if (currentNamespace.isNullOrEmpty()) {
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    val targetNamespace = if (project.name == "telephony") "com.shounakmulay.telephony" else project.group.toString()
                    setNamespace.invoke(androidExt, targetNamespace)
                }
            } catch (e: Exception) {
                try {
                    configure<com.android.build.gradle.BaseExtension> {
                        if (namespace.isNullOrEmpty()) {
                            namespace = if (project.name == "telephony") "com.shounakmulay.telephony" else project.group.toString()
                        }
                    }
                } catch (ignored: Exception) {}
            }
        }
    }

    if (state.executed) {
        patchNamespace()
    } else {
        afterEvaluate {
            patchNamespace()
        }
    }
}

plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.5.0" apply false
}