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

/// Un aviso de la empresa se muestra como notificación del teléfono (suena y
/// queda en la barra), igual que un push, aunque el entorno no tenga push
/// configurado (sin credenciales FCM) ni sockets desplegados.
///
/// Se entera de un aviso nuevo por DOS vías, con la app abierta:
/// - en tiempo real, por el canal del usuario (`inbox.updated`), si hay socket;
/// - por un sondeo propio cada [_pollEvery] de la cantidad sin leer, que cubre
///   el caso SIN socket (la mayoría hoy): así "avisos con push" funciona igual.
///
/// Reglas: al entrar activa las notificaciones (pide el permiso una vez); solo
/// avisa cuando la cantidad sin leer SUBE (marcar leído no dispara nada); y si
/// el push FCM ya está registrado no hace nada (ese aviso lo muestra el push y
/// saldría dos veces). Background real (app cerrada) necesita FCM: eso no lo
/// cubre este sondeo, solo la app en primer plano.
class InboxAlerts extends Notifier<void> {
  /// Sin leer de la última vez (`null` = todavía no se sabe la base).
  int? _unread;
  bool _disposed = false;
  Timer? _poll;

  /// Cada cuánto se consulta la cantidad sin leer mientras no hay socket.
  static const Duration _pollEvery = Duration(seconds: 45);

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
      _poll?.cancel();
      _poll = null;
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
    if (_disposed) return;
    _poll ??= Timer.periodic(_pollEvery, (_) => _pollUnread());
  }

  /// Sondeo: ¿subió la cantidad sin leer desde la última vez? → notificar.
  Future<void> _pollUnread() async {
    if (_disposed) return;
    try {
      final unread = await ref
          .read(inboxRemoteDataSourceProvider)
          .unreadCount();
      await _notifyIfGrew(unread);
    } on Object {
      // Sin señal: se reintenta en el próximo tick.
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
    await _notifyIfGrew(raw.toInt());
  }

  /// Muestra la notificación del teléfono si [unread] subió respecto de la
  /// última base conocida (y el push FCM no la va a mostrar él).
  Future<void> _notifyIfGrew(int unread) async {
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
