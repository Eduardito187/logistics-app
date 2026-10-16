import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Abre la navegación externa hacia una coordenada, sin depender de Google
/// Maps (ADR 013).
///
/// En Android se intenta primero el esquema `geo:` (lo resuelve cualquier app
/// de mapas instalada que respete OSM). Si no hay app que lo maneje, o en otras
/// plataformas, se abre OpenStreetMap en el navegador como fallback.
///
/// Devuelve `true` si se pudo lanzar alguna opción, `false` si ninguna.
Future<bool> openExternalNavigation(
  double lat,
  double lng, {
  String? label,
}) async {
  final String coords = '$lat,$lng';

  if (!kIsWeb && Platform.isAndroid) {
    // geo:lat,lng?q=lat,lng(etiqueta) para que la app de mapas muestre el pin.
    final String query = label != null && label.isNotEmpty
        ? '$coords(${Uri.encodeComponent(label)})'
        : coords;
    final Uri geoUri = Uri.parse('geo:$coords?q=$query');
    if (await canLaunchUrl(geoUri)) {
      final bool launched = await launchUrl(
        geoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return true;
      }
    }
  }

  // Fallback universal: OpenStreetMap en el navegador.
  final Uri osmUri = Uri.parse(
    'https://www.openstreetmap.org/?mlat=$lat&mlon=$lng#map=17/$lat/$lng',
  );
  return launchUrl(osmUri, mode: LaunchMode.externalApplication);
}
