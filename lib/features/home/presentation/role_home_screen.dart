import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';

/// Inicio según el rol de la sesión. Cada flujo de la lista se convierte en su propio
/// feature (picking, loading, route, delivery, store_reception) a medida que se construye.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final role = session.role;

    return Scaffold(
      appBar: AppBar(
        title: Text(role.label),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(role.icon, size: 40),
            title: Text(session.userName),
            subtitle: Text(role.label),
          ),
          const Divider(),
          for (final task in role.tasks)
            Card(
              child: ListTile(
                title: Text(task),
                trailing: const Chip(label: Text('Próximamente')),
              ),
            ),
        ],
      ),
    );
  }
}
