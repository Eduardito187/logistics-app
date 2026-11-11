import 'dart:convert';

/// Credenciales de acceso a UNA impresora (como las que pide Windows al
/// imprimir en una impresora con autenticación de dominio).
///
/// Las ingresa el operario: ni Android 10+ ni iOS permiten a una app leer la
/// identidad EAP del WiFi corporativo ni las credenciales del dominio.
///
/// Nunca se imprimen en logs: [toString] oculta la contraseña y el código.
class PrinterCredentials {
  const PrinterCredentials({
    required this.username,
    this.password,
    this.userCode,
    this.domain,
    this.secureToken,
  });

  /// Usuario (sin dominio). Va en `requesting-user-name` (IPP) y en PJL.
  final String username;

  /// Contraseña para autenticación HTTP (Basic/Digest) por IPP.
  final String? password;

  /// Código de usuario (Ricoh "User Code"): va por PJL `USERCODE`.
  final String? userCode;

  /// Dominio Windows/LDAP opcional (`DOMINIO\usuario` en la autenticación).
  final String? domain;

  /// Clave de "Impresión bloqueada" de Ricoh, tal cual la emite su driver
  /// (`@PJL SET JOBPASSWORD5`, base64 opaco). NO se descifra: es un token fijo
  /// del PIN del usuario. Si está, el trabajo va como `SECUREJOB` y queda
  /// retenido para liberarlo en el panel. Se obtiene capturando una vez la
  /// salida del driver; por eso vive en "Opciones avanzadas", no lo tipea el
  /// operario.
  final String? secureToken;

  bool get hasPassword => (password ?? '').isNotEmpty;
  bool get hasUserCode => (userCode ?? '').trim().isNotEmpty;
  bool get hasSecureToken => (secureToken ?? '').trim().isNotEmpty;

  /// Usuario para la autenticación HTTP: `DOMINIO\usuario` si hay dominio.
  String get authUser {
    final d = domain?.trim() ?? '';
    final u = username.trim();
    return d.isEmpty ? u : '$d\$u';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'username': username,
    if (hasPassword) 'password': password,
    if (hasUserCode) 'userCode': userCode!.trim(),
    if ((domain ?? '').trim().isNotEmpty) 'domain': domain!.trim(),
    if (hasSecureToken) 'secureToken': secureToken!.trim(),
  };

  static PrinterCredentials? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final user = json['username'];
    if (user is! String) return null;
    String? opt(String key) {
      final v = json[key];
      return v is String && v.isNotEmpty ? v : null;
    }

    return PrinterCredentials(
      username: user,
      password: opt('password'),
      userCode: opt('userCode'),
      domain: opt('domain'),
      secureToken: opt('secureToken'),
    );
  }

  String encode() => jsonEncode(toJson());

  static PrinterCredentials? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PrinterCredentials &&
      other.username == username &&
      other.password == password &&
      other.userCode == userCode &&
      other.domain == domain &&
      other.secureToken == secureToken;

  @override
  int get hashCode =>
      Object.hash(username, password, userCode, domain, secureToken);

  /// Sin secretos: apto para logs/diagnóstico.
  @override
  String toString() =>
      'PrinterCredentials(user: $authUser, password: '
      '${hasPassword ? '***' : '-'}, userCode: ${hasUserCode ? '***' : '-'})';
}
