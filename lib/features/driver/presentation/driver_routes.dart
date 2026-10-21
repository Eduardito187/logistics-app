import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/user_role.dart';
import '../../../core/navigation/role_task.dart';
import 'active_delivery_screen.dart';
import 'checklist_screen.dart';
import 'driver_route_screen.dart';
import 'fuel_screen.dart';
import 'incident_screen.dart';
import 'live_gps_screen.dart';
import 'load_scan_screen.dart';
import 'maintenance_due_screen.dart';
import 'my_day_screen.dart';
import 'odometer_screen.dart';
import 'vehicle_summary_screen.dart';

/// Tarjetas del chofer en el inicio del rol. La descarga, la prueba de entrega y
/// la entrega fallida se abren desde la parada dentro de la ruta.
const List<RoleTask> driverTasks = [
  RoleTask(
    id: 'driver-active-delivery',
    label: 'Entrega en curso',
    subtitle: 'Mapa, datos del cliente, pedido y entrega con foto',
    icon: Icons.local_shipping,
    route: '/driver/delivery',
    roles: {UserRole.driver},
    accent: true,
  ),
  RoleTask(
    id: 'driver-route',
    label: 'Mi ruta de hoy',
    subtitle: 'Paradas en mapa y lista, con navegación',
    icon: Icons.map,
    route: '/driver/route',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-my-day',
    label: 'Mi día',
    subtitle: 'Entregadas, pendientes y tiempos de hoy',
    icon: Icons.today,
    route: '/driver/my-day',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-checklist',
    label: 'Checklist pre-salida',
    subtitle: 'Inspección del camión antes de salir',
    icon: Icons.checklist,
    route: '/driver/checklist',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-load',
    label: 'Carga del camión',
    subtitle: 'Escanear bultos a cargar',
    icon: Icons.upload,
    route: '/driver/load',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-gps',
    label: 'Rastreo del camión',
    subtitle: 'Estado del GPS automático (siempre activo en ruta)',
    icon: Icons.my_location,
    route: '/driver/gps',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-incident',
    label: 'Reportar incidente',
    subtitle: 'Avería o accidente en ruta',
    icon: Icons.report,
    route: '/driver/incident',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-summary',
    label: 'Resumen del vehículo',
    subtitle: 'Costos y utilización',
    icon: Icons.insights,
    route: '/driver/summary',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-fuel',
    label: 'Cargar combustible',
    subtitle: 'Registrar litros, precio y odómetro',
    icon: Icons.local_gas_station,
    route: '/driver/fuel',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-odometer',
    label: 'Odómetro',
    subtitle: 'Registrar el kilometraje actual',
    icon: Icons.speed,
    route: '/driver/odometer',
    roles: {UserRole.driver},
  ),
  RoleTask(
    id: 'driver-maintenance',
    label: 'Mantenimiento',
    subtitle: 'Servicios por vencer del vehículo',
    icon: Icons.build,
    route: '/driver/maintenance',
    roles: {UserRole.driver},
  ),
];

/// Rutas go_router del chofer. Las pantallas por parada (descarga, POD, fallida)
/// se navegan con Navigator pasando la parada por constructor.
final List<RouteBase> driverRoutes = [
  GoRoute(
    path: '/driver/route',
    builder: (context, state) => const DriverRouteScreen(),
  ),
  GoRoute(
    path: '/driver/delivery',
    builder: (context, state) => const ActiveDeliveryScreen(),
  ),
  GoRoute(
    path: '/driver/my-day',
    builder: (context, state) => const MyDayScreen(),
  ),
  GoRoute(
    path: '/driver/checklist',
    builder: (context, state) => const ChecklistScreen(),
  ),
  GoRoute(
    path: '/driver/load',
    builder: (context, state) => const LoadScanScreen(),
  ),
  GoRoute(
    path: '/driver/gps',
    builder: (context, state) => const LiveGpsScreen(),
  ),
  GoRoute(
    path: '/driver/incident',
    builder: (context, state) => const IncidentScreen(),
  ),
  GoRoute(
    path: '/driver/summary',
    builder: (context, state) => const VehicleSummaryScreen(),
  ),
  GoRoute(
    path: '/driver/fuel',
    builder: (context, state) => const FuelScreen(),
  ),
  GoRoute(
    path: '/driver/odometer',
    builder: (context, state) => const OdometerScreen(),
  ),
  GoRoute(
    path: '/driver/maintenance',
    builder: (context, state) => const MaintenanceDueScreen(),
  ),
];
