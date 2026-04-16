// Root build configuration for the EDU_X Flutter Android project.
// Configures shared repositories, build directories, and compile SDK enforcement.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect build output to the Flutter-standard shared build directory
// so that `flutter build` artifacts are consolidated outside `android/`.
val newBuildDir: Directory = rootProject.layout.buildDirectory
    .dir("../../build")
    .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Mirror the redirected build directory for every subproject
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))

    // Enforce a minimum compileSdk across all Android library subprojects.
    // This prevents build failures from transitive plugin dependencies that
    // ship with an older compileSdk than the host app requires.
    // Must be registered BEFORE evaluationDependsOn to avoid "already evaluated" errors.
    project.plugins.withId("com.android.library") {
        project.extensions.configure<com.android.build.gradle.LibraryExtension> {
            if ((compileSdk ?: 0) < 36) {
                compileSdk = 36
            }
        }
    }

    // Ensure :app is evaluated first so its configuration is available
    // to dependent subprojects (e.g., plugin projects referencing app config).
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
