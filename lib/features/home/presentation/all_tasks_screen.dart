import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/navigation/feature_tasks.dart';
import '../../../core/navigation/role_task.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/big_action_tile.dart';

/// Pestaña "Tareas": TODAS las acciones del rol en grande, para quien quiere el
/// menú completo (el Inicio muestra solo lo principal).
///
/// Responsive: una columna en teléfono, dos o tres en tablet
/// ([SliverAdaptiveCardRows], sin alto fijo → no se deforma con letra grande),
/// y el contenido se centra con un ancho máximo en tablets anchas.
class AllTasksScreen extends ConsumerWidget {
  const AllTasksScreen({super.key});

  /// Ancho máximo del contenido para que no se estire en tablets anchas.
  static const double _maxWidth = 1080;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Session? session = ref.watch(sessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    // Todas las tareas visibles para la sesión (rol + permiso) menos "Ajustes":
    // eso vive en la pestaña Perfil.
    final tasks = visibleTasksFor(session, ref.watch(featureTasksProvider))
        .where((t) => t.id != 'settings')
        .toList();

    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width > _maxWidth + 32 ? (width - _maxWidth) / 2 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      body: tasks.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Sin tareas por ahora',
              message: 'No hay flujos disponibles para este rol todavía.',
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    16,
                    sidePadding,
                    navScrollBottomPadding(context),
                  ),
                  sliver: SliverAdaptiveCardRows(
                    itemCount: tasks.length,
                    maxColumns: 3,
                    itemBuilder: (context, i) => _Tile(task: tasks[i]),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Un tile que navega a la ruta de la tarea (pantalla completa sobre el shell).
class _Tile extends StatelessWidget {
  const _Tile({required this.task});

  final RoleTask task;

  @override
  Widget build(BuildContext context) {
    return BigActionTile(
      label: task.label,
      subtitle: task.subtitle,
      icon: task.icon,
      accent: task.accent,
      onTap: () => context.push(task.route),
    );
  }
}
