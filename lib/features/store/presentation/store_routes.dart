import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/shipment.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'counter_pickup_screen.dart';
import 'node_reception_screen.dart';
import 'pickup_pod_screen.dart';
import 'reception_detail_screen.dart';

/// Tarjetas de inicio del rol Tienda.
const List<RoleTask> storeTasks = [
  RoleTask(
    id: 'store-reception',
    label: 'Recepción de mercadería',
    subtitle: 'Contra manifiesto',
    icon: Icons.inventory_2,
    route: '/store/reception',
    roles: {UserRole.store},
    accent: true,
  ),
  RoleTask(
    id: 'store-pickup',
    label: 'Recojo en tienda',
    subtitle: 'Entrega en mostrador',
    icon: Icons.storefront,
    route: '/store/pickup',
    roles: {UserRole.store},
  ),
];

/// Rutas del flujo Tienda. Las pantallas de detalle reciben su contexto por
/// `extra` (records tipados) desde `context.push`.
final List<RouteBase> storeRoutes = [
  GoRoute(
    path: '/store/reception',
    builder: (context, state) => const NodeReceptionScreen(),
  ),
  GoRoute(
    path: '/store/reception/detail',
    builder: (context, state) =>
        ReceptionDetailScreen(args: state.extra! as ReceptionArgs),
  ),
  GoRoute(
    path: '/store/pickup',
    builder: (context, state) => const CounterPickupScreen(),
  ),
  GoRoute(
    path: '/store/pickup/pod',
    builder: (context, state) =>
        PickupPodScreen(shipment: state.extra! as Shipment),
  ),
];
