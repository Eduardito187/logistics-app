import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/models/staff_inbox_item.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/push/local_alerts.dart';
import '../../../../core/push/push_controller.dart';
import '../../../../core/push/push_status.dart';
import '../../../../core/realtime/pusher_socket.dart';
import '../../../../core/realtime/realtime_bus.dart';
import '../../data/datasources/inbox_remote_data_source.dart';
import '../widgets/inbox_item_card.dart';

/// Un aviso de la empresa que llega por la conexión de TIEMPO REAL se muestra
/// como notificación del teléfono (suena y queda en la barra), igual que un
/// push, aunque el entorno no tenga push configurado.
///
/// - Al entrar activa las notificaciones (pide el permiso del sistema una vez).
/// - Solo avisa cuando la cantidad de avisos sin leer SUBE: marcar uno como
///   leído no dispara nada.
/// - Si el push del teléfono ya está registrado no hace nada: ese aviso lo
///   muestra el push y saldría dos veces.
class InboxAlerts extends Notifier<void> {
  /// Sin leer que informó el último aviso (`null` = todavía no se sabe).
  int? _unread;
  bool _disposed = false;

  @override
  void build() {
    _disposed = false;
    _unread = null;
    final signedIn = ref.watch(
      sessionProvider.select((s) => (s?.token != null, s?.userName)),
    );
    final stop = ref
        .read(realtimeBusProvider)
        .listen(RealtimeTopic.user, _onEvent);
    ref.onDispose(() {
      _disposed = true;
      stop();
    });
    if (!signedIn.$1) return;
    // Fuera del build: pide permiso y hace red.
    scheduleMicrotask(_start);
  }

  Future<void> _start() async {
    if (_disposed) return;
    unawaited(ref.read(localAlertsProvider).enable());
    try {
      final unread = await ref
          .read(inboxRemoteDataSourceProvider)
          .unreadCount();
      if (!_disposed) _unread ??= unread;
    } on Object {
      // Sin la cuenta inicial, el primer aviso que llegue fija la base.
    }
  }

  /// ¿El push del teléfono ya está activo? Entonces el aviso lo muestra él.
  bool get _pushActive {
    if (!ref.read(pushConfiguredProvider)) return false;
    return ref.read(pushRegistrationProvider).state ==
        PushRegistrationState.registered;
  }

  Future<void> _onEvent(RealtimeEvent event) async {
    if (_disposed || event.name != 'inbox.updated') return;
    final raw = event.data['unread'];
    if (raw is! num) return;
    final unread = raw.toInt();
    final before = _unread;
    _unread = unread;
    if (before == null || unread <= before || _pushActive) return;
    StaffInboxItem? latest;
    try {
      final page = await ref.read(inboxRemoteDataSourceProvider).list(1);
      for (final item in page.items) {
        if (!inboxPending(item) && !(item.read ?? false)) {
          latest = item;
          break;
        }
      }
    } on Object {
      // Sin el detalle se avisa igual, con un texto genérico.
    }
    if (_disposed) return;
    await ref
        .read(localAlertsProvider)
        .show(
          title: latest == null ? 'Tenés un aviso nuevo' : inboxTitle(latest),
          body: latest?.body,
        );
  }
}

final inboxAlertsProvider = NotifierProvider<InboxAlerts, void>(
  InboxAlerts.new,
);
