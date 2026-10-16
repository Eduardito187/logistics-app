import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'order_preparation_screen.dart';
import 'orders_worklist_screen.dart';
import 'prepare_order_screen.dart';

/// Tarjetas de acción del rol preparador/andén en el inicio.
/// Acción principal: la worklist de pedidos por preparar. Se conserva el
/// ingreso/escaneo manual del número de pedido como acción secundaria.
const List<RoleTask> pickingTasks = [
  RoleTask(
    id: 'picking-orders',
    label: 'Pedidos por preparar',
    subtitle: 'Lista de pedidos para armar y cargar',
    icon: Icons.list_alt,
    route: '/picking/orders',
    roles: {UserRole.picker},
    accent: true,
  ),
  RoleTask(
    id: 'picking-prepare',
    label: 'Ingresar pedido',
    subtitle: 'Escanear o escribir el número de pedido',
    icon: Icons.qr_code_scanner,
    route: '/picking/prepare',
    roles: {UserRole.picker},
  ),
];

/// Rutas go_router del feature de preparación.
final List<RouteBase> pickingRoutes = [
  GoRoute(
    path: '/picking/orders',
    builder: (context, state) => const OrdersWorklistScreen(),
  ),
  GoRoute(
    path: '/picking/prepare',
    builder: (context, state) => const PrepareOrderScreen(),
  ),
  GoRoute(
    path: '/picking/order/:orderNumber',
    builder: (context, state) => OrderPreparationScreen(
      orderNumber: state.pathParameters['orderNumber']!,
    ),
  ),
];
