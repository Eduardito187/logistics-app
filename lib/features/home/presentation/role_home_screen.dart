import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session.dart';
import '../../../core/layout/breakpoints.dart';
import '../../../core/navigation/feature_tasks.dart';
import '../../../core/navigation/role_task.dart';
import '../../../core/widgets/notifications_button.dart';
import 'home_prefetch.dart';
import 'widgets/profile_header.dart';
import 'widgets/task_card.dart';

/// Ancho máximo del contenido del inicio en tablets grandes: la grilla de 3
/// columnas no se estira de borde a borde y el perfil queda alineado con ella.
const double _homeMaxWidth = 1080;

/// Separación entre tarjetas (filas y columnas).
const double _gap = 12;

/// Inicio según el rol de la sesión. Muestra el perfil del usuario y las
/// tarjetas de acción que cada feature aporta para ese rol: una columna en
/// teléfono y grilla de 2–3 columnas en tablet.
///
/// Al montarse precarga en segundo plano los datos de la primera pantalla del
/// rol ([HomePrefetcher]): sin spinner ni espera; el primer toque abre al
/// instante.
class RoleHomeScreen extends ConsumerStatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  ConsumerState<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends ConsumerState<RoleHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Después del primer frame: el inicio se pinta primero y la precarga no
    // modifica providers mientras se construye el árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = ref.read(sessionProvider)?.role;
      if (role != null) ref.read(homePrefetcherProvider)(ref, role);
    });
  }

  @override
  Widget build(BuildContext context) {
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

    // Margen lateral que centra el contenido en tablets anchas (0 en teléfono
    // salvo el padding normal). `sizeOf` solo reconstruye si cambia el tamaño.
    final width = MediaQuery.sizeOf(context).width;
    final sidePadding = width > _homeMaxWidth + 32
        ? (width - _homeMaxWidth) / 2
        : 16.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            actions: [
              // Único acceso a las notificaciones (todos los roles).
              const NotificationsButton(),
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              ),
            ],
            // Sin título: el rol ya se ve en el ProfileHeader y el título del
            // FlexibleSpaceBar se agrandaba al expandir (se veía tosco).
            flexibleSpace: FlexibleSpaceBar(
              background: ProfileHeader(
                name: session.userName,
                role: role.label,
                icon: role.icon,
                horizontalPadding: sidePadding,
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
              padding: EdgeInsets.fromLTRB(sidePadding, 16, sidePadding, 24),
              sliver: _TaskSliver(
                tasks: tasks,
                columns: AppBreakpoints.columnsFor(width),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjetas del inicio: lista en teléfono (alto natural) y grilla con alto fijo
/// de tarjeta en tablet. Ambas perezosas (solo construyen lo visible).
class _TaskSliver extends StatelessWidget {
  const _TaskSliver({required this.tasks, required this.columns});

  final List<RoleTask> tasks;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return SliverList.separated(
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: _gap),
        itemBuilder: (context, i) => TaskCard(task: tasks[i]),
      );
    }
    // Mismo alto para todas las tarjetas: título y subtítulo de hasta 2 líneas
    // cada uno (con elipsis), según el tema y la letra del sistema.
    final extent = TaskCard.gridExtent(context);
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: _gap,
        crossAxisSpacing: _gap,
        mainAxisExtent: extent,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => TaskCard(task: tasks[i], maxLines: TaskCard.gridLines),
        childCount: tasks.length,
      ),
    );
  }
}
