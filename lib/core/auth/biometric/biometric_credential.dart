import 'package:flutter/foundation.dart';

/// Cuenta guardada para ingresar con biometría en este teléfono (una sola).
///
/// Vive en el almacén seguro (Keystore / Keychain) y solo existe si el usuario
/// activó el ingreso con biometría.
@immutable
class BiometricCredential {
  const BiometricCredential({
    required this.email,
    required this.password,
    this.name,
  });

  /// Lee el JSON guardado; `null` si está incompleto.
  static BiometricCredential? fromJson(Map<String, Object?> json) {
    final email = json['email'];
    final password = json['password'];
    final name = json['name'];
    if (email is! String || email.isEmpty) return null;
    if (password is! String || password.isEmpty) return null;
    return BiometricCredential(
      email: email,
      password: password,
      name: name is String && name.isNotEmpty ? name : null,
    );
  }

  final String email;
  final String password;

  /// Nombre del usuario para "como Juan Pérez" (opcional).
  final String? name;

  Map<String, Object?> toJson() => {
    'email': email,
    'password': password,
    if (name != null) 'name': name,
  };

  /// ¿Es la misma cuenta? (el correo no distingue mayúsculas).
  bool isFor(String otherEmail) =>
      email.trim().toLowerCase() == otherEmail.trim().toLowerCase();

  /// Cómo se muestra la cuenta en el login: el nombre o el correo enmascarado.
  String get displayName => name ?? maskEmail(email);

  /// "juan.perez@dismac.com" → "juan.p…@dismac.com". Muestra lo justo para
  /// reconocer la cuenta en un teléfono compartido sin exponer el correo.
  static String maskEmail(String email) {
    final value = email.trim();
    final at = value.indexOf('@');
    final local = at < 0 ? value : value.substring(0, at);
    final domain = at < 0 ? '' : value.substring(at);
    if (local.length <= 1) return value;
    final visible = local.length > 6 ? 6 : (local.length / 2).ceil();
    if (visible >= local.length) return value;
    return '${local.substring(0, visible)}…$domain';
  }

  @override
  bool operator ==(Object other) =>
      other is BiometricCredential &&
      other.email == email &&
      other.password == password &&
      other.name == name;

  @override
  int get hashCode => Object.hash(email, password, name);

  // Sin la contraseña: nunca debe terminar en un log.
  @override
  String toString() => 'BiometricCredential(${maskEmail(email)})';
}
