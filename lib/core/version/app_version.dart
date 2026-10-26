import 'package:flutter/foundation.dart';

/// Versión semántica simple `mayor.menor.parche` para comparar la app con la
/// mínima que exige el backend. Ignora sufijos (`-beta`, `+42`): el build no
/// cuenta para compatibilidad, solo la versión.
@immutable
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, [this.minor = 0, this.patch = 0]);

  final int major;
  final int minor;
  final int patch;

  // Compiladas una sola vez: se parsea la versión mínima de cada respuesta.
  static final RegExp _suffix = RegExp('[+-]');
  static final RegExp _semver = RegExp(r'^(\d+)(?:\.(\d+))?(?:\.(\d+))?$');

  /// Parsea `1`, `1.2`, `1.2.3`, `v1.2.3`, `1.2.3+45`, `1.2.3-rc.1`.
  /// `null` si el texto no es una versión válida (se ignora sin bloquear).
  static AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    var text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) text = text.substring(1);
    text = text.split(_suffix).first;
    final match = _semver.firstMatch(text);
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2) ?? '0'),
      int.parse(match.group(3) ?? '0'),
    );
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(AppVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
