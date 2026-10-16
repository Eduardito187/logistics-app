// Configuración global de los tests (el framework de test la ejecuta una vez,
// envolviendo a todos los tests del proyecto).
//
// En WSL/Linux el paquete `sqlite3` (que usa Drift) abre por defecto la
// librería sin versión `libsqlite3.so`, que suele NO existir: solo está
// `libsqlite3.so.0`. Sin esto, cualquier test que instancie `AppDatabase`
// (Drift sobre `NativeDatabase.memory()`) revienta con "Failed to load dynamic
// library 'libsqlite3.so'". Acá redirigimos la carga a la versión .0 (con
// respaldo a la sin versión), sin tocar el sistema ni requerir root.
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

// `sqlite3` entra de forma transitiva por Drift; se usa solo en test para
// redirigir la carga de la librería nativa.
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, _openSqliteOnLinux);
  }
  await testMain();
}

DynamicLibrary _openSqliteOnLinux() {
  for (final name in const ['libsqlite3.so', 'libsqlite3.so.0']) {
    try {
      return DynamicLibrary.open(name);
    } on Object {
      // Prueba el siguiente nombre.
    }
  }
  // Último intento: deja que falle con el error original si ninguno abrió.
  return DynamicLibrary.open('libsqlite3.so');
}
