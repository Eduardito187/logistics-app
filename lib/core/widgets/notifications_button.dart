import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Acceso a la bandeja de notificaciones desde la AppBar. Es el único acceso
/// (no hay tarjeta en el inicio) y está en todos los roles.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificaciones',
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => context.push('/notifications'),
    );
  }
}
