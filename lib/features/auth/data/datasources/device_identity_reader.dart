import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/device_identity.dart';

/// Averigua el modelo del equipo para mandarlo como `device.name` en el login.
///
/// Por qué existe: el proyecto NO tiene `device_info_plus` (ni se puede agregar
/// en este turno) y tampoco hay un canal nativo propio que exponga datos del
/// equipo — los canales de `android/app/src/main/kotlin/` dan memoria, batería,
/// red, biometría y widgets, pero ninguno `Build.MODEL`. Desde Dart estándar,
/// `Platform.operatingSystemVersion` en Android devuelve la versión del
/// **kernel** (ilegible para un chofer), así que no sirve como nombre.
///
/// Lo que queda sin dependencias nuevas: leer las propiedades del sistema de
/// `build.prop`, que es de lectura pública en Android y trae el modelo y el
/// nombre comercial del equipo. Es "mejor esfuerzo": si el archivo no está, no
/// se puede leer o tarda, se devuelve [DeviceIdentity.unknown] y el login sigue
/// con el nombre genérico de siempre.
///
/// QUÉ FALTA para tener el modelo exacto y garantizado: `device_info_plus`
/// (`AndroidDeviceInfo.model` / `IosDeviceInfo.utsname.machine`) o un
/// `MethodChannel` propio que devuelva `Build.MANUFACTURER`/`Build.MODEL` en
/// Android y `utsname` en iOS. Al tenerlo, se cambia solo [read]: el resto de
/// la app (login y pantalla de dispositivos) no se toca. En iOS este lector
/// siempre devuelve desconocido.
class DeviceIdentityReader {
  DeviceIdentityReader({
    Future<String> Function(String path)? readFile,
    String? platformName,
    this.timeout = const Duration(milliseconds: 300),
  }) : _readFile = readFile ?? _readFileFromDisk,
       _platformName = platformName ?? _currentPlatformName();

  /// Lectura de un archivo de propiedades (seam para tests).
  final Future<String> Function(String path) _readFile;

  /// Plataforma actual ('android', 'ios', …). Inyectable en tests.
  final String _platformName;

  /// Tope de espera: el login no puede quedarse esperando el disco.
  final Duration timeout;

  /// Archivos de propiedades del sistema, en orden de preferencia. Se juntan
  /// todos los que se puedan leer (los equipos reparten las claves entre
  /// `/system`, `/vendor` y `/odm`).
  static const propertyFiles = <String>[
    '/system/build.prop',
    '/vendor/build.prop',
    '/odm/etc/build.prop',
  ];

  /// Resultado memoizado: el modelo no cambia en la vida del proceso, así que
  /// un segundo login (o un reintento) no vuelve a tocar el disco.
  Future<DeviceIdentity>? _cached;

  /// Datos del equipo. **Nunca lanza y nunca tarda más que [timeout]**: el
  /// login es un punto sensible y preferimos un nombre genérico antes que un
  /// error o una demora.
  Future<DeviceIdentity> read() => _cached ??= _read();

  Future<DeviceIdentity> _read() async {
    // Solo Android: en iOS/web no hay `build.prop` (ver comentario de clase).
    if (_platformName != 'android') return DeviceIdentity.unknown;
    try {
      final props = await _readProperties().timeout(timeout);
      if (props.isEmpty) return DeviceIdentity.unknown;
      return DeviceIdentity(
        model: _composeModel(props),
        osVersion: _composeOsVersion(props),
      );
    } on Object {
      // Sin permisos, sin archivo, timeout: equipo desconocido.
      return DeviceIdentity.unknown;
    }
  }

  Future<Map<String, String>> _readProperties() async {
    final props = <String, String>{};
    for (final path in propertyFiles) {
      try {
        final content = await _readFile(path);
        // Las primeras claves leídas ganan: `/system` manda sobre `/vendor`.
        for (final entry in parseProperties(content).entries) {
          props.putIfAbsent(entry.key, () => entry.value);
        }
      } on Object {
        // Este archivo no está o no se puede leer: se prueba el siguiente.
      }
    }
    return props;
  }

  /// Parsea un `build.prop`: líneas `clave=valor`, comentarios con `#`.
  static Map<String, String> parseProperties(String content) {
    final props = <String, String>{};
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separator = line.indexOf('=');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      props.putIfAbsent(key, () => value);
    }
    return props;
  }

  /// Nombre comercial del equipo: `marca + nombre de venta o modelo`.
  /// Se prefiere el nombre de venta (lo que dice la caja: "Magic5 Lite") y, si
  /// no está, el modelo técnico ("CPH2749"), que igual es reconocible porque
  /// aparece en Ajustes > Acerca del teléfono.
  static String? _composeModel(Map<String, String> props) {
    final marketName = _firstOf(props, const [
      'ro.product.marketname',
      'ro.product.vendor.marketname',
      'ro.product.odm.marketname',
      'ro.vendor.oplus.market.name',
      'ro.config.marketing_name',
    ]);
    final model = _firstOf(props, const [
      'ro.product.model',
      'ro.product.vendor.model',
      'ro.product.odm.model',
      'ro.product.system.model',
    ]);
    final brand = _firstOf(props, const [
      'ro.product.manufacturer',
      'ro.product.vendor.manufacturer',
      'ro.product.brand',
      'ro.product.vendor.brand',
    ]);

    final device = marketName ?? model;
    if (device == null) return null;
    final label = _withBrand(brand: brand, device: device);
    // Tope defensivo: el nombre se muestra en una tarjeta y lo guarda el
    // backend; un `build.prop` raro no puede meter un texto gigante.
    return label.length <= 60 ? label : label.substring(0, 60).trim();
  }

  /// Pega la marca adelante salvo que el modelo ya la traiga ("Samsung SM-A135"
  /// no debe quedar "Samsung Samsung SM-A135").
  static String _withBrand({required String? brand, required String device}) {
    if (brand == null) return device;
    final pretty = _prettyBrand(brand);
    if (device.toLowerCase().startsWith(brand.toLowerCase())) return device;
    return '$pretty $device';
  }

  /// "Android 14" a partir de `ro.build.version.release`.
  static String? _composeOsVersion(Map<String, String> props) {
    final release = _firstOf(props, const [
      'ro.build.version.release',
      'ro.system.build.version.release',
    ]);
    return release == null ? null : 'Android $release';
  }

  static String? _firstOf(Map<String, String> props, List<String> keys) {
    for (final key in keys) {
      final value = props[key]?.trim();
      // Se descartan los placeholders que dejan algunas ROMs.
      if (value == null || value.isEmpty || value == 'unknown') continue;
      return value;
    }
    return null;
  }

  /// Presenta la marca como se la conoce: "samsung" → "Samsung", "HONOR" →
  /// "Honor". Si ya viene con mayúsculas intercaladas se deja tal cual, porque
  /// esa es la grafía de la marca ("OnePlus", "iPhone").
  static String _prettyBrand(String value) {
    if (value.length < 2) return value.toUpperCase();
    final isUniformCase =
        value == value.toLowerCase() || value == value.toUpperCase();
    if (!isUniformCase) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  static Future<String> _readFileFromDisk(String path) =>
      File(path).readAsString();

  /// `Platform.operatingSystem` aislado: en tests se inyecta el valor.
  static String _currentPlatformName() {
    try {
      return Platform.operatingSystem;
    } on Object {
      return 'unknown';
    }
  }
}

/// Lector del modelo del equipo. Se crea una sola vez por app para que el
/// resultado quede memoizado (ver [DeviceIdentityReader.read]).
final deviceIdentityReaderProvider = Provider<DeviceIdentityReader>(
  (ref) => DeviceIdentityReader(),
);
