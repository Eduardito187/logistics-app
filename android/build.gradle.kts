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

// Plugins de terceros que todavía compilan con Java 8 (flutter_foreground_task,
// flutter_local_notifications, geolocator_android, permission_handler_android,
// workmanager_android). Con el JDK 21 eso da "source/target value 8 is
// obsolete" en cada build. Se los sube a Java 17 (igual que :app) sin tocar el
// pub cache, alineando también Kotlin: si Java y Kotlin difieren, el plugin de
// Kotlin corta la build con "Inconsistent JVM-target compatibility".
// Además se silencian sus notas de API deprecada: es código ajeno que no
// podemos corregir (nuestro código sí las sigue mostrando, :app no entra acá).
subprojects {
    if (name == "app") return@subprojects

    // Fuente de verdad de javac: las compileOptions de la extensión `android`
    // del plugin. AGP pisa lo que se ponga directo en JavaCompile (por eso antes
    // javac quedaba en 1.8 y Kotlin en 17: "Inconsistent JVM-target") y bloquea
    // el DSL tras finalizeDsl. Se usa el hook oficial `finalizeDsl`, registrado
    // apenas se aplica el plugin de librería: corre DESPUÉS del bloque
    // `android { compileOptions { 1.8 } }` del plugin y antes del bloqueo.
    plugins.withId("com.android.library") {
        extensions.getByName("androidComponents").withGroovyBuilder {
            "finalizeDsl"(
                object : Action<Any> {
                    override fun execute(androidExtension: Any) {
                        androidExtension
                            .withGroovyBuilder { getProperty("compileOptions") }
                            .withGroovyBuilder {
                                setProperty("sourceCompatibility", JavaVersion.VERSION_17)
                                setProperty("targetCompatibility", JavaVersion.VERSION_17)
                            }
                    }
                },
            )
        }
    }

    val alignJvmTarget: Project.() -> Unit = {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_17.toString()
            targetCompatibility = JavaVersion.VERSION_17.toString()
            options.compilerArgs.addAll(listOf("-Xlint:-deprecation", "-XDsuppressNotes"))
        }
        // Tareas de Kotlin (compileDebugKotlin, compileProfileKotlin…). Se
        // accede sin tipos para no depender del classpath del script raíz: el
        // enum JvmTarget se resuelve con el classloader del propio plugin.
        tasks.matching { it.name.startsWith("compile") && it.name.endsWith("Kotlin") }
            .configureEach {
                val jvmTargetClass = Class.forName(
                    "org.jetbrains.kotlin.gradle.dsl.JvmTarget",
                    true,
                    javaClass.classLoader,
                )
                val jvm17 = jvmTargetClass.enumConstants.first { (it as Enum<*>).name == "JVM_17" }
                withGroovyBuilder {
                    getProperty("compilerOptions").withGroovyBuilder {
                        getProperty("jvmTarget").withGroovyBuilder { "set"(jvm17) }
                    }
                }
            }
    }
    // Después de que el plugin aplique su propio `compileOptions`/`kotlinOptions`
    // (que fijan 1.8), así este valor es el que queda.
    if (state.executed) alignJvmTarget() else afterEvaluate { alignJvmTarget() }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
