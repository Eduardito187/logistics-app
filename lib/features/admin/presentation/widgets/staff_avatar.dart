import 'package:flutter/material.dart';

/// Foto de la persona o, si no tiene, sus iniciales. La foto llega por un
/// enlace temporal del backend: si venció o falla, quedan las iniciales.
class StaffAvatar extends StatelessWidget {
  const StaffAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
  });

  final String? name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final initials = Text(
      _initials(name),
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: radius * 0.7),
    );
    if (url == null || url.isEmpty) {
      return CircleAvatar(radius: radius, child: initials);
    }
    // Decodificada al tamaño del avatar (dp x densidad, tope 3x).
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 3.0);
    final cache = (radius * 2 * dpr).round();
    return CircleAvatar(
      radius: radius,
      child: ClipOval(
        child: Image.network(
          url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          cacheWidth: cache,
          cacheHeight: cache,
          errorBuilder: (_, _, _) => initials,
        ),
      ),
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
