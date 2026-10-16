import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../../core/widgets/section_card.dart';

/// Sección de sesión: muestra el usuario y rol actual, permite renovar el token
/// del dispositivo (`/app/auth/refresh`) y cerrar sesión.
class SessionSection extends ConsumerWidget {
  const SessionSection({required this.session, super.key});

  final Session? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SectionCard(
      title: 'Sesión',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(session?.role.icon ?? Icons.person_outline),
            title: Text(session?.userName ?? 'Sin sesión'),
            subtitle: Text(session?.role.label ?? '—'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            // Renueva el token del dispositivo (/app/auth/refresh). Solo con
            // sesión real del backend (el dev-login no tiene token).
            onPressed: session?.token == null
                ? null
                : () async {
                    try {
                      await ref.read(sessionProvider.notifier).refreshToken();
                      if (context.mounted) {
                        showSuccessSnack(context, 'Sesión renovada.');
                      }
                    } on ApiException catch (e) {
                      if (context.mounted) showErrorSnack(context, e);
                    }
                  },
            icon: const Icon(Icons.autorenew),
            label: const Text('Renovar sesión'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: session == null
                ? null
                : () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
