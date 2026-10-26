import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/carrier/presentation/carrier_pickup_screen.dart';
import '../../features/driver/presentation/active_delivery_screen.dart';
import '../../features/home/presentation/all_tasks_screen.dart';
import '../../features/home/presentation/role_home_screen.dart';
import '../../features/notifications/presentation/notifications_list_screen.dart';
import '../../features/picking/presentation/orders_worklist_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/store/presentation/node_reception_screen.dart';
import '../../features/supervisor/presentation/supervisor_dashboard_screen.dart';
import '../auth/session.dart';
import '../auth/user_role.dart';
import '../widgets/floating_pill_nav_bar.dart';
import 'app_nav.dart';
import 'feature_tasks.dart';

/// Pantalla "acción principal" del rol, que ocupa la PESTAÑA CENTRAL del shell.
Widget _centerScreenFor(UserRole role) {
  switch (role) {
    case UserRole.driver:
      return const ActiveDeliveryScreen();
    case UserRole.picker:
      return const OrdersWorklistScreen();
    case UserRole.store:
      return const NodeReceptionScreen();
    case UserRole.carrier:
      return const CarrierPickupScreen();
    case UserRole.supervisor:
      return const SupervisorDashboardScreen();
  }
}

/// Caparazón de las pantallas principales. CINCO pestañas en un [IndexedStack]
/// (Inicio, Tareas, Centro, Avisos, Perfil): tocar cualquiera —incluida la
/// central— cambia el contenido EN LA MISMA PANTALLA (no redirige). La barra
/// FLOTA por encima del contenido (`extendBody: true`), transparente, sin tapar
/// con una banda de fondo.
///
/// La pestaña central (pantalla del rol, puede ser pesada: GPS/mapa) se arma
/// SOLO cuando está seleccionada, para no correr en segundo plano.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  Widget build(BuildContext context) {
    final Session? session = ref.watch(sessionProvider);
    if (session == null) {
      return const SizedBox.shrink();
    }
    final index = ref.watch(homeTabProvider);
    final tasks = ref.watch(featureTasksProvider);
    // Etiqueta/ícono de la pestaña central: la acción estrella del rol (con el
    // mismo gating por permiso).
    final center = centerActionFor(
      session.role,
      visibleTasksFor(session, tasks),
    );

    return Scaffold(
      // extendBody: la barra flota SOBRE el contenido (se ve a los lados y el
      // contenido pasa por debajo), no reserva una banda opaca.
      extendBody: true,
      body: IndexedStack(
        sizing: StackFit.expand,
        index: index,
        children: [
          // Inicio y Tareas son livianas: siempre vivas (estado/scroll).
          const RoleHomeScreen(),
          const AllTasksScreen(),
          // Las pesadas o con efectos al iniciar (GPS/mapa en el centro,
          // impresora Bluetooth en Perfil, polling en Avisos) se construyen
          // SOLO cuando están activas: así no corren en segundo plano al
          // arrancar (eso disparaba el permiso BT y parecía cierre).
          index == 2 ? _centerScreenFor(session.role) : const SizedBox.shrink(),
          index == 3
              ? const NotificationsListScreen()
              : const SizedBox.shrink(),
          index == 4 ? const SettingsScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: FloatingPillNavBar(
        sideTabs: kPrimaryNavTabs,
        currentIndex: index,
        onTap: (i) => ref.read(homeTabProvider.notifier).set(i),
        centerLabel: center?.label ?? 'Acción',
        centerIcon: center?.icon ?? Icons.bolt,
      ),
    );
  }
}
