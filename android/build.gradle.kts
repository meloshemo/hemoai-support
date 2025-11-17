import com.android.build.api.dsl.ApplicationExtension
import com.android.build.api.dsl.LibraryExtension
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
    // Harmonize lint to avoid unit test classpath issues during lint on plugins
    plugins.withId("com.android.application") {
        extensions.configure<ApplicationExtension> {
            lint {
                checkTestSources = false
                ignoreTestSources = true
                abortOnError = false
            }
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<LibraryExtension> {
            lint {
                checkTestSources = false
                ignoreTestSources = true
                abortOnError = false
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
