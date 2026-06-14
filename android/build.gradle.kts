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
                // Safely get the existing namespace using reflection
                val getNamespace = androidExt.javaClass.getMethod("getNamespace")
                val currentNamespace = getNamespace.invoke(androidExt) as? String
                
                // If it is blank, define a safe fallback namespace
                if (currentNamespace.isNullOrEmpty()) {
                    val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                    // We default to telephony's package namespace or use the subproject group
                    val targetNamespace = if (project.name == "telephony") "com.shounakmulay.telephony" else project.group.toString()
                    setNamespace.invoke(androidExt, targetNamespace)
                }
            } catch (e: Exception) {
                // Fallback to standard Gradle block configuration if reflection fails
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

    // Safety guard to avoid "already evaluated" lifecycle errors
    if (state.executed) {
        patchNamespace()
    } else {
        afterEvaluate {
            patchNamespace()
        }
    }
}