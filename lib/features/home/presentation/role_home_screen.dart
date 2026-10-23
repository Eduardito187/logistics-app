import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session.dart';
import '../../../core/brand/distrack_app_bar_logo.dart';
import '../../../core/layout/adaptive_card_rows.dart';
import '../../../core/layout/nav_clearance.dart';
import '../../../core/navigation/app_nav.dart';
import '../../../core/navigation/feature_tasks.dart';
import '../../../core/navigation/role_task.dart';
import '../../../core/widgets/empty_state.dart';
import 'widgets/big_action_tile.dart';
import 'widgets/greeting_header.dart';
import 'widgets/hero_task_card.dart';
import 'widgets/home_section_title.dart';

/// Inicio del rol: un panel glanceable. Header FIJO (logo + salir) que queda
/// pegado arriba al hacer scroll; debajo, saludo, tarjeta héroe de la acción
/// principal y accesos rápidos grandes. El menú completo vive en "Tareas".
///
/// Diseñado para choferes mayores: pocos elementos, todo grande, un camino
/// obvio. El contenido pasa por debajo del footer flotante (padding inferior).
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  /// Cuántos accesos rápidos mostrar bajo el héroe (el resto, en Tareas).
  static const int _quickCount = 4;

  /// Ancho máximo del contenido; centra en tablets anchas.
  static const double _maxWidth = 900;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final Session? session = ref.watch(sessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final role = session.role;
    final roleTasks = visibleTasksFor(session, ref.watch(featureTasksProvider))
        .where((t) => t.id != 'settings')
        .toList();

    final RoleTask? hero = centerActionFor(role, roleTasks);
    final quick = roleTasks
        .where((t) => t.id != hero?.id)
        .take(_quickCount)
        .toList();
    final isEmpty = hero == null && quick.isEmpty;

    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width > _maxWidth + 32
        ? (width - _maxWidth) / 2
        : 16.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header FIJO: logo a la izquierda, salir a la derecha. Queda pegado
          // arriba al hacer scroll (pinned) con una sombra sutil al desplazar.
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            titleSpacing: sidePadding,
            scrolledUnderElevation: 3,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: const DisTrackAppBarLogo(height: 24),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              ),
              SizedBox(width: sidePadding - 4),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GreetingHeader(
                    name: session.userName,
                    roleLabel: role.label,
                    roleIcon: role.icon,
                  ),
                  const SizedBox(height: 20),
                  if (hero != null) ...[
                    HeroTaskCard(
                      title: hero.label,
                      subtitle: hero.subtitle,
                      icon: hero.icon,
                      statusLabel: 'Acción principal',
                      // Es la pestaña central: cambiá a ella en vez de redirigir.
                      onTap: () => ref.read(homeTabProvider.notifier).set(2),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (quick.isNotEmpty) ...[
                    HomeSectionTitle(
                      title: 'Accesos rápidos',
                      actionLabel: 'Ver todo',
                      onAction: () => ref.read(homeTabProvider.notifier).set(1),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
          if (isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 24),
                child: EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Todo en orden',
                  message: 'No hay flujos disponibles para este rol todavía.',
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                sidePadding,
                0,
                sidePadding,
                navScrollBottomPadding(context),
              ),
              sliver: SliverAdaptiveCardRows(
                itemCount: quick.length,
                maxColumns: 2,
                itemBuilder: (context, i) {
                  final task = quick[i];
                  return BigActionTile(
                    label: task.label,
                    subtitle: task.subtitle,
                    icon: task.icon,
                    accent: task.accent,
                    onTap: () => context.push(task.route),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
