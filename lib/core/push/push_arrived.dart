import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contador de notificaciones push recibidas con la app ABIERTA.
///
/// Las bandejas (notificaciones y avisos de la empresa) lo observan: cuando
/// llega un push se vuelven a pedir solas, sin que el usuario refresque.
class PushArrivedNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final pushArrivedProvider = NotifierProvider<PushArrivedNotifier, int>(
  PushArrivedNotifier.new,
);
