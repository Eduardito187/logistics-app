import 'package:flutter/foundation.dart';

import '../../icons/icons.dart';
import 'biometric_type.dart';

/// Qué biometría tiene REALMENTE este teléfono y cómo nombrarla en la UI.
///
/// Regla del dueño: nunca se nombra un sensor que el teléfono no tiene. Un
/// iPhone con Face ID dice "Face ID"; un Android solo con huella dice "huella";
/// con huella y rostro, "huella o rostro".
@immutable
class BiometricCapabilities {
  const BiometricCapabilities({
    required this.supported,
    required this.enrolled,
    this.types = const {},
    this.platformLabel,
    this.platform,
  });

  /// Sin biometría (o canal nativo ausente, p. ej. en tests o web).
  static const unsupported = BiometricCapabilities(
    supported: false,
    enrolled: false,
  );

  /// Lee el mapa del canal (`capabilities`). Datos raros → no soportado.
  factory BiometricCapabilities.fromMap(
    Map<Object?, Object?> raw, {
    TargetPlatform? platform,
  }) {
    final supported = raw['supported'] == true;
    final rawTypes = raw['types'];
    final label = raw['platformLabel'];
    return BiometricCapabilities(
      supported: supported,
      enrolled: supported && raw['enrolled'] == true,
      types: {
        if (rawTypes is List)
          for (final t in rawTypes) ?BiometricType.fromWire(t),
      },
      platformLabel: label is String && label.isNotEmpty ? label : null,
      platform: platform,
    );
  }

  /// Hay hardware biométrico.
  final bool supported;

  /// Hay al menos un rostro/huella registrado en el teléfono.
  final bool enrolled;

  /// Sensores que el teléfono declara (puede venir vacío en algunos Android).
  final Set<BiometricType> types;

  /// Nombre que da el sistema (iOS: "Face ID"/"Touch ID"), si lo manda.
  final String? platformLabel;

  /// Plataforma para elegir los textos; `null` = [defaultTargetPlatform]
  /// (en tests se fija con `debugDefaultTargetPlatformOverride`).
  final TargetPlatform? platform;

  /// Se puede usar ya: hay sensor y algo registrado.
  bool get isAvailable => supported && enrolled;

  bool get _isApple {
    final p = platform ?? defaultTargetPlatform;
    return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  }

  /// Nombre corto para "Ingresar con …": "Face ID", "Touch ID", "huella",
  /// "reconocimiento facial", "huella o rostro"…
  String get label {
    if (_isApple) {
      if (types.contains(BiometricType.face)) return 'Face ID';
      if (types.contains(BiometricType.fingerprint)) return 'Touch ID';
      if (types.contains(BiometricType.iris)) return 'Optic ID';
      return platformLabel ?? 'biometría del teléfono';
    }
    final nouns = _androidNouns;
    if (nouns.isEmpty) return 'biometría del teléfono';
    // Solo rostro: "rostro" a secas suena raro en "Ingresar con rostro".
    if (types.length == 1 && types.contains(BiometricType.face)) {
      return 'reconocimiento facial';
    }
    return _joinOr(nouns);
  }

  /// [label] con artículo, para frases como "Configurá tu huella…".
  String get labelWithArticle {
    final name = label;
    if (_isApple) {
      return name == 'biometría del teléfono' ? 'la $name' : name;
    }
    if (_androidNouns.isEmpty) return 'la $name';
    if (name == 'reconocimiento facial') return 'el $name';
    return 'tu $name';
  }

  /// Título del switch del perfil y del botón del login.
  String get switchTitle => 'Ingresar con $label';

  /// Texto del ítem deshabilitado cuando hay sensor pero nada registrado.
  String get setupHint =>
      'Configurá $labelWithArticle en los ajustes del teléfono para usarlo '
      'acá.';

  /// Ícono que mejor representa el sensor (no hay dibujo de huella propio:
  /// rostro → perfil, iris → ojo, huella/varios/genérico → candado).
  AppIcon get appIcon {
    if (types.length == 1) {
      if (types.contains(BiometricType.face)) return AppIcon.profile;
      if (types.contains(BiometricType.iris)) return AppIcon.visibility;
    }
    return AppIcon.security;
  }

  /// Sustantivos en orden estable: huella, rostro, iris.
  List<String> get _androidNouns => [
    if (types.contains(BiometricType.fingerprint)) 'huella',
    if (types.contains(BiometricType.face)) 'rostro',
    if (types.contains(BiometricType.iris)) 'iris',
  ];

  static String _joinOr(List<String> items) {
    if (items.length == 1) return items.single;
    final head = items.sublist(0, items.length - 1).join(', ');
    return '$head o ${items.last}';
  }

  @override
  bool operator ==(Object other) =>
      other is BiometricCapabilities &&
      other.supported == supported &&
      other.enrolled == enrolled &&
      setEquals(other.types, types) &&
      other.platformLabel == platformLabel &&
      other.platform == platform;

  @override
  int get hashCode => Object.hash(
    supported,
    enrolled,
    Object.hashAllUnordered(types),
    platformLabel,
    platform,
  );

  @override
  String toString() =>
      'BiometricCapabilities(supported: $supported, enrolled: $enrolled, '
      'types: $types)';
}
