import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/navigation/feature_tasks.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/sync_badge.dart';
import 'widgets/profile_header.dart';
import 'widgets/task_card.dart';

/// Inicio según el rol de la sesión. Muestra el perfil del usuario y las
/// tarjetas de acción que cada feature aporta para ese rol.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final role = session.role;
    final abilities = session.abilities;
    final tasks = ref.watch(featureTasksProvider).where((t) {
      if (!t.visibleFor(role)) {
        return false;
      }
      final required = t.requiredAbility;
      // Regla de seguridad: si la tarjeta no pide permiso, o si todavía no
      // sabemos qué puede el usuario (abilities vacías: login sin `/me`, red o
      // permiso caído), NO ocultamos por ability — caemos a filtro solo-rol
      // para no dejar el inicio vacío. El gating por permiso solo se aplica
      // cuando hay abilities cargadas.
      if (required == null || abilities.isEmpty) {
        return true;
      }
      return session.can(required);
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            actions: [
              const SyncBadge(),
              IconButton(
                tooltip: 'Sincronización',
                icon: const Icon(Icons.sync_alt),
                onPressed: () => context.push(AppRoutes.sync),
              ),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(role.label),
              background: ProfileHeader(
                name: session.userName,
                role: role.label,
                icon: role.icon,
              ),
            ),
          ),
          if (tasks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No hay flujos disponibles para este rol todavía.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: tasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => TaskCard(task: tasks[i]),
              ),
            ),
        ],
      ),
    );
  }
}
