allprojects {
    repositories {
        google()
        mavenCentral()
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

// file_picker 11 skips the Kotlin plugin on AGP 9 and expects built-in
// Kotlin. This app turns built-in Kotlin off, so compile that plugin with KGP.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        if (project.name != "file_picker") return@withPlugin
        if (!project.pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            project.pluginManager.apply("org.jetbrains.kotlin.android")
        }
        project.extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension>("kotlin") {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
