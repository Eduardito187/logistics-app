import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/models/settlement.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'carrier_assignment_screen.dart';
import 'carrier_cheapest_tariff_screen.dart';
import 'carrier_deliver_screen.dart';
import 'carrier_pickup_screen.dart';
import 'carrier_settlement_detail_screen.dart';
import 'carrier_settlements_screen.dart';
import 'carrier_tariff_screen.dart';

/// Tarjetas de inicio del transportista externo.
const List<RoleTask> carrierTasks = [
  RoleTask(
    id: 'carrier-pickup',
    label: 'Escanear al recoger',
    icon: Icons.upload_file,
    route: '/carrier/pickup',
    roles: {UserRole.carrier},
    accent: true,
  ),
  RoleTask(
    id: 'carrier-deliver',
    label: 'Escanear al entregar',
    icon: Icons.task_alt,
    route: '/carrier/deliver',
    roles: {UserRole.carrier},
  ),
  RoleTask(
    id: 'carrier-settlements',
    label: 'Mis liquidaciones',
    icon: Icons.receipt_long,
    route: '/carrier/settlements',
    roles: {UserRole.carrier},
  ),
];

/// Rutas del flujo del transportista externo.
final List<RouteBase> carrierRoutes = [
  GoRoute(
    path: '/carrier/pickup',
    builder: (context, state) => const CarrierPickupScreen(),
  ),
  GoRoute(
    path: '/carrier/deliver',
    builder: (context, state) => const CarrierDeliverScreen(),
  ),
  GoRoute(
    path: '/carrier/settlements',
    builder: (context, state) => const CarrierSettlementsScreen(),
  ),
  GoRoute(
    path: '/carrier/settlements/:settlementId',
    builder: (context, state) => CarrierSettlementDetailScreen(
      settlementId: state.pathParameters['settlementId']!,
      initial: state.extra is Settlement ? state.extra! as Settlement : null,
    ),
  ),
  GoRoute(
    path: '/carrier/tariff',
    builder: (context, state) => const CarrierTariffScreen(),
  ),
  GoRoute(
    path: '/carrier/assignment',
    builder: (context, state) => const CarrierAssignmentScreen(),
  ),
  GoRoute(
    path: '/carrier/tariff/cheapest',
    builder: (context, state) => const CarrierCheapestTariffScreen(),
  ),
];
