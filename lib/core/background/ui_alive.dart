import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Nombre del puerto que la UI registra mientras está en primer plano.
const String kUiAlivePortName = 'bo.com.dismac.logistics.ui_alive';

/// `true` si la UI de la app está abierta y en primer plano (mismo proceso).
/// La tarea de fondo lo consulta para no duplicar el drenado de la cola.
bool isUiAliveInForeground() =>
    IsolateNameServer.lookupPortByName(kUiAlivePortName) != null;

/// Registra el puerto "UI viva" mientras la app está en primer plano y lo
/// quita al pasar a segundo plano: ahí sí la tarea de fondo tiene que drenar
/// (la UI puede quedar dormida horas sin cambios de red).
class UiAliveBeacon with WidgetsBindingObserver {
  ReceivePort? _port;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    _register();
  }

  void _register() {
    if (_port != null) return;
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(kUiAlivePortName);
    IsolateNameServer.registerPortWithName(port.sendPort, kUiAlivePortName);
    _port = port;
  }

  void _unregister() {
    IsolateNameServer.removePortNameMapping(kUiAlivePortName);
    _port?.close();
    _port = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _register();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _unregister();
    }
  }
}
