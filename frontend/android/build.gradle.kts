import org.gradle.api.tasks.Delete // Importation nécessaire

buildscript {
    // --- LA CORRECTION EST ICI ---
    // On définit une variable locale simple.
    val kotlinVersion = "1.9.23"
    // On n'utilise plus extra[...]

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.2.0")
    
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Syntaxe Kotlin pour enregistrer la tâche "clean"
tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
