// Configuración global de los tests e2e (el framework la ejecuta una vez,
// envolviendo a todos los tests de `integration_test/`).
//
// Mismo problema y solución que `test/flutter_test_config.dart`: en WSL/Linux
// el paquete `sqlite3` (vía Drift) abre por defecto `libsqlite3.so` sin
// versión, que suele NO existir (solo está `libsqlite3.so.0`). Los flujos e2e
// usan `AppDatabase(NativeDatabase.memory())` y la cola offline real, así que
// sin esto revientan con "Failed to load dynamic library 'libsqlite3.so'".
// `flutter_test_config.dart` NO se hereda entre carpetas de test, por eso hay
// una copia acá. El override es solo para Linux: en Windows no toca nada.
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
