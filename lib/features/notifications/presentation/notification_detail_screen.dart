import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/notification_view.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/async_value_view.dart';
import '../domain/usecases/suppress_notification.dart';
import 'controllers/notifications_controller.dart';
import 'widgets/notification_detail_body.dart';

/// Detalle de una notificación: tipo, estado, envío, canales y reintentos.
/// Permite suprimir una notificación que aún está en cola.
class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  bool _suppressing = false;

  Future<void> _suppress() async {
    setState(() => _suppressing = true);
    try {
      await ref.read(suppressNotificationProvider).call(widget.id);
      ref.invalidate(notificationDetailProvider(widget.id));
      ref.invalidate(notificationsListProvider);
      if (!mounted) return;
      showSuccessSnack(context, 'Notificación suprimida.');
    } on ApiException catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _suppressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(notificationDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Notificación')),
      body: AsyncValueView<NotificationView>(
        value: detail,
        onRetry: () => ref.invalidate(notificationDetailProvider(widget.id)),
        data: (notification) => NotificationDetailBody(
          notification: notification,
          suppressing: _suppressing,
          onSuppress: _suppress,
        ),
      ),
    );
  }
}
