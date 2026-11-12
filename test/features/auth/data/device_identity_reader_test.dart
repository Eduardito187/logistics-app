import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/auth/data/datasources/device_identity_reader.dart';
import 'package:logistics_app/features/auth/data/device_display_name.dart';
import 'package:logistics_app/features/auth/domain/entities/device_identity.dart';

// Lector del modelo del equipo (sin device_info_plus): lee las propiedades del
// sistema de build.prop y arma un nombre que el usuario reconozca en "Mis
// dispositivos". Contrato duro: NUNCA lanza y NUNCA tarda más que su timeout.

/// Lector con los archivos de propiedades simulados en memoria.
DeviceIdentityReader _reader(
  Map<String, String> files, {
  String platform = 'android',
  Duration timeout = const Duration(milliseconds: 300),
}) => DeviceIdentityReader(
  platformName: platform,
  timeout: timeout,
  readFile: (path) async {
    final content = files[path];
    if (content == null) throw StateError('no existe $path');
    return content;
  },
);

const _oneplus = '''
# build.prop de prueba
ro.product.manufacturer=OnePlus
ro.product.model=CPH2749
ro.build.version.release=15
''';

void main() {
  group('DeviceIdentityReader', () {
    test('arma "marca + modelo" y la versión de Android', () async {
      final identity = await _reader({'/system/build.prop': _oneplus}).read();

      expect(identity.model, 'OnePlus CPH2749');
      expect(identity.osVersion, 'Android 15');
      expect(identity.hasModel, isTrue);
    });

    test('prefiere el nombre comercial (lo que dice la caja)', () async {
      final identity = await _reader({
        '/system/build.prop': '''
ro.product.manufacturer=HONOR
ro.product.model=RKY-LX3
ro.product.marketname=Magic5 Lite
''',
      }).read();

      expect(identity.model, 'Honor Magic5 Lite');
    });

    test('no repite la marca si el modelo ya la trae', () async {
      final identity = await _reader({
        '/system/build.prop': '''
ro.product.manufacturer=samsung
ro.product.model=Samsung Galaxy A15
''',
      }).read();

      expect(identity.model, 'Samsung Galaxy A15');
    });

    test('junta claves repartidas entre /system y /vendor', () async {
      final identity = await _reader({
        '/system/build.prop': 'ro.build.version.release=13',
        '/vendor/build.prop': '''
ro.product.vendor.manufacturer=Xiaomi
ro.product.vendor.model=Redmi 12C
''',
      }).read();

      expect(identity.model, 'Xiaomi Redmi 12C');
      expect(identity.osVersion, 'Android 13');
    });

    test('descarta los placeholders "unknown" de algunas ROMs', () async {
      final identity = await _reader({
        '/system/build.prop': '''
ro.product.manufacturer=unknown
ro.product.model=unknown
ro.product.vendor.model=TC26
''',
      }).read();

      expect(identity.model, 'TC26');
    });

    test('sin propiedades usables: equipo desconocido, sin lanzar', () async {
      final identity = await _reader({
        '/system/build.prop': '# solo comentarios\n\nclave_sin_valor=\n',
      }).read();

      expect(identity.model, isNull);
      expect(identity.hasModel, isFalse);
    });

    test('ningún archivo legible: equipo desconocido, sin lanzar', () async {
      final identity = await _reader(const {}).read();

      expect(identity.hasModel, isFalse);
    });

    test('si leer el archivo lanza, no propaga el error', () async {
      final reader = DeviceIdentityReader(
        platformName: 'android',
        readFile: (_) async => throw Exception('permiso denegado'),
      );

      await expectLater(reader.read(), completion(isA<DeviceIdentity>()));
      expect((await reader.read()).hasModel, isFalse);
    });

    // El login no puede esperar al disco: se corta y sigue.
    test('una lectura colgada se corta por timeout', () async {
      final reader = DeviceIdentityReader(
        platformName: 'android',
        timeout: const Duration(milliseconds: 20),
        // Nunca responde: simula un disco/FS trabado.
        readFile: (_) => Completer<String>().future,
      );

      final identity = await reader.read().timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw StateError('el lector se colgó'),
      );
      expect(identity.hasModel, isFalse);
    });

    test('fuera de Android no toca el disco', () async {
      var reads = 0;
      final reader = DeviceIdentityReader(
        platformName: 'ios',
        readFile: (_) async {
          reads++;
          return _oneplus;
        },
      );

      expect((await reader.read()).hasModel, isFalse);
      expect(reads, 0);
    });

    test('memoiza: dos logins seguidos leen el disco una sola vez', () async {
      var reads = 0;
      final reader = DeviceIdentityReader(
        platformName: 'android',
        readFile: (path) async {
          reads++;
          if (path != '/system/build.prop') throw StateError('no existe');
          return _oneplus;
        },
      );

      final first = await reader.read();
      final second = await reader.read();

      expect(first.model, 'OnePlus CPH2749');
      expect(second.model, 'OnePlus CPH2749');
      // Una pasada por la lista de archivos, no dos.
      expect(reads, DeviceIdentityReader.propertyFiles.length);
    });

    test('recorta un nombre absurdamente largo', () async {
      final identity = await _reader({
        '/system/build.prop': 'ro.product.model=${'M' * 200}',
      }).read();

      expect(identity.model!.length, lessThanOrEqualTo(60));
    });
  });

  group('deviceDisplayName', () {
    test('con modelo conocido manda el modelo', () {
      expect(
        deviceDisplayName(const DeviceIdentity(model: 'OnePlus CPH2749')),
        'OnePlus CPH2749',
      );
    });

    test('sin modelo cae al nombre genérico de siempre', () {
      expect(deviceDisplayName(DeviceIdentity.unknown), genericDeviceName);
      expect(
        deviceDisplayName(const DeviceIdentity(model: '   ')),
        genericDeviceName,
      );
    });
  });
}
