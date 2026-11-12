import 'dart:convert';
import 'dart:math' as math;

import 'md5.dart';

/// Arma la cabecera `Authorization` para un desafío `WWW-Authenticate`
/// (Basic o Digest MD5, RFC 7617 / RFC 7616). Kerberos/NTLM no se pueden sin
/// el sistema operativo: en ese caso se intenta Basic (muchas impresoras lo
/// aceptan igual contra el LDAP/AD).
abstract final class HttpAuthorization {
  /// `Basic base64(usuario:contraseña)`.
  static String basic(String user, String password) =>
      'Basic ${base64.encode(utf8.encode('$user:$password'))}';

  /// Cabecera para [challenges] (valores de `WWW-Authenticate`). Prefiere
  /// Digest si la impresora lo ofrece; si no, Basic.
  static String forChallenges(
    List<String> challenges, {
    required String method,
    required String path,
    required String user,
    required String password,
    String? cnonce,
  }) {
    for (final c in challenges) {
      final trimmed = c.trim();
      if (trimmed.toLowerCase().startsWith('digest')) {
        final params = parseParams(trimmed.substring(6));
        final algorithm = (params['algorithm'] ?? 'MD5').toUpperCase();
        if (algorithm == 'MD5' && params['nonce'] != null) {
          return digest(
            params,
            method: method,
            path: path,
            user: user,
            password: password,
            cnonce: cnonce,
          );
        }
      }
    }
    return basic(user, password);
  }

  /// `Digest …` con qop=auth si el servidor lo ofrece.
  static String digest(
    Map<String, String> params, {
    required String method,
    required String path,
    required String user,
    required String password,
    String? cnonce,
  }) {
    final realm = params['realm'] ?? '';
    final nonce = params['nonce'] ?? '';
    final opaque = params['opaque'];
    final qops = (params['qop'] ?? '')
        .split(',')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty);
    final useQop = qops.contains('auth');
    final ha1 = Md5.hex(utf8.encode('$user:$realm:$password'));
    final ha2 = Md5.hex(utf8.encode('$method:$path'));
    const nc = '00000001';
    final client = cnonce ?? _randomHex(8);
    final response = useQop
        ? Md5.hex(utf8.encode('$ha1:$nonce:$nc:$client:auth:$ha2'))
        : Md5.hex(utf8.encode('$ha1:$nonce:$ha2'));
    final parts = <String>[
      'username="${_quote(user)}"',
      'realm="${_quote(realm)}"',
      'nonce="${_quote(nonce)}"',
      'uri="${_quote(path)}"',
      'algorithm=MD5',
      'response="$response"',
      if (opaque != null) 'opaque="${_quote(opaque)}"',
      if (useQop) ...['qop=auth', 'nc=$nc', 'cnonce="$client"'],
    ];
    return 'Digest ${parts.join(', ')}';
  }

  /// Parámetros `clave=valor` / `clave="valor"` de un desafío.
  static Map<String, String> parseParams(String text) {
    final out = <String, String>{};
    final pattern = RegExp(
      r'([A-Za-z0-9_-]+)\s*=\s*(?:"((?:[^"\\]|\\.)*)"|([^\s,]+))',
    );
    for (final m in pattern.allMatches(text)) {
      final value = m.group(2) ?? m.group(3) ?? '';
      out[m.group(1)!.toLowerCase()] = value.replaceAll(r'\"', '"');
    }
    return out;
  }

  static String _quote(String v) => v.replaceAll('"', r'\"');

  static String _randomHex(int bytes) {
    final rnd = math.Random.secure();
    return List<String>.generate(
      bytes,
      (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
