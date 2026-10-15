import org.jetbrains.kotlin.gradle.dsl.KotlinVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    configurations.all {
        resolutionStrategy {
            force("androidx.browser:browser:1.8.0")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    if (name == "sentry_flutter") {
        // Sentry 8 is pinned for its iOS wrapper. Its Kotlin sources also work
        // with 1.8, the minimum supported by the current Kotlin compiler.
        afterEvaluate {
            tasks.withType<KotlinCompile>().configureEach {
                compilerOptions.languageVersion.set(KotlinVersion.KOTLIN_1_8)
                compilerOptions.apiVersion.set(KotlinVersion.KOTLIN_1_8)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
