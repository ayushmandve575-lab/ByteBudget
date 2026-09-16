allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.projectDirectory.dir("build"))
}

// 🚀 NATIVE GRADLE PLUGINS SPECIFICATION ENGINE
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            extensions.configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(36) // Standard native tool method configuration
                
                // Keep the auto-namespace fallback active for older modules safely
                if (namespace == null) {
                    namespace = project.group.toString()
                }
            }
        }
    }
}