import 'package:url_launcher/url_launcher.dart';

final RegExp _nonDial = RegExp(r'[^0-9+]');

/// Abre el marcador del teléfono con el número del cliente (no llama solo: el
/// chofer confirma). Devuelve `false` si el dispositivo no puede marcar.
Future<bool> dialPhone(String phone) {
  final digits = phone.replaceAll(_nonDial, '');
  return launchUrl(Uri(scheme: 'tel', path: digits));
}
