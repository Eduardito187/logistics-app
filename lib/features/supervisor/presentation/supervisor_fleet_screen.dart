import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/vehicle_live.dart';
import '../../../core/icons/icons.dart';
import '../../../core/power/power_status_notifier.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/fleet_map.dart';

/// Cada cuánto se piden de nuevo las posiciones de la flota mientras la
/// pantalla está a la vista. 30 s: la telemetría no cambia más rápido de forma
/// útil para el supervisor y en un teléfono de 1 GB cada refresco cuesta red,
/// JSON y un reagrupado del mapa.
const Duration fleetRefreshInterval = Duration(seconds: 30);

/// Intervalo con ahorro de energía o batería < 20 % (menos radio y CPU).
const Duration fleetRefreshIntervalSaving = Duration(seconds: 90);

/// Flota en vivo: mapa OSM con la última posición conocida de cada camión.
///
/// Refresco automático cada [fleetRefreshInterval], que se **detiene**:
/// - con la app en segundo plano (pantalla apagada, otra app encima), y
/// - cuando otra pantalla tapa a esta (p. ej. se abrió un detalle encima):
///   el `Navigator` apaga el `TickerMode` de las rutas tapadas.
///
/// Al volver a estar a la vista se refresca una vez enseguida (las posiciones
/// quedaron viejas) y se reanuda el intervalo. Nunca hay dos pedidos solapados.
class SupervisorFleetScreen extends ConsumerStatefulWidget {
  const SupervisorFleetScreen({super.key});

  @override
  ConsumerState<SupervisorFleetScreen> createState() =>
      _SupervisorFleetScreenState();
}

class _SupervisorFleetScreenState extends ConsumerState<SupervisorFleetScreen>
    with WidgetsBindingObserver {
  Timer? _timer;

  /// Ciudad elegida en el filtro; `null` = todo el país.
  String? _city;

  /// App en primer plano (o apenas inactiva, p. ej. con la cortina bajada).
  bool _appActive = true;

  /// Ruta a la vista (no tapada por otra pantalla). `null` hasta el primer
  /// `didChangeDependencies`.
  bool? _visible;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appActive = lifecycle == null || _isActive(lifecycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    if (visible == _visible) return;
    // Primera vez: el provider ya está cargando, no hace falta refrescar.
    final refreshNow = _visible != null && visible;
    _visible = visible;
    _syncPolling(refreshNow: refreshNow);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = _isActive(state);
    if (active == _appActive) return;
    _appActive = active;
    _syncPolling(refreshNow: active);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  static bool _isActive(AppLifecycleState state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

  /// Arranca o detiene el timer según la visibilidad y el estado de la app.
  void _syncPolling({required bool refreshNow}) {
    final shouldRun = _appActive && (_visible ?? false);
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    // En una microtarea (al terminar el frame en curso): Riverpod pausa las
    // suscripciones de una ruta tapada y las reanuda en el build, que corre
    // después de `didChangeDependencies`; invalidar antes se perdía.
    if (refreshNow) scheduleMicrotask(_refresh);
    final saving = ref.read(powerStatusProvider).shouldSaveEnergy;
    _timer = Timer.periodic(
      saving ? fleetRefreshIntervalSaving : fleetRefreshInterval,
      (_) => _refresh(),
    );
  }

  void _refresh() {
    if (!mounted) return;
    // Sin pedidos solapados: si el anterior no volvió, se espera al próximo.
    if (ref.read(fleetLiveProvider).isLoading) return;
    ref.invalidate(fleetLiveProvider);
  }

  @override
  Widget build(BuildContext context) {
    final fleet = ref.watch(fleetLiveProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flota en vivo'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            // Gira mientras se piden las posiciones (manual o automático).
            icon: AnimatedAppIcon(
              AppIcon.refresh,
              state: fleet.isLoading ? AppIconState.loading : AppIconState.idle,
              excludeFromSemantics: true,
            ),
            onPressed: () => ref.invalidate(fleetLiveProvider),
          ),
        ],
      ),
      body: AsyncValueView<List<VehicleLive>>(
        value: fleet,
        onRetry: () => ref.invalidate(fleetLiveProvider),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return const EmptyState(
              icon: AppIcon.map,
              title: 'Sin camiones en vivo',
              message: 'No hay posiciones de telemetría por ahora.',
            );
          }
          // Ciudades con camiones (la ciudad es la de la sede del camión). Con
          // un backend que aún no la manda no hay filtro: se ve todo.
          final cities = fleetCities(vehicles);
          final city = cities.contains(_city) ? _city : null;
          final shown = city == null
              ? vehicles
              : [
                  for (final v in vehicles)
                    if (v.city == city) v,
                ];
          return Column(
            children: [
              if (cities.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      _cityChip('Todo el país', null, vehicles.length, city),
                      for (final name in cities)
                        _cityChip(
                          name,
                          name,
                          vehicles.where((v) => v.city == name).length,
                          city,
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: FleetMap(
                  // Otra ciudad = otro encuadre: el mapa se arma de nuevo.
                  key: ValueKey<String?>(city),
                  vehicles: shown,
                  fitAll: cities.isNotEmpty,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cityChip(String label, String? value, int count, String? selected) =>
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text('$label · $count'),
          selected: selected == value,
          onSelected: (_) => setState(() => _city = value),
        ),
      );
}

/// Ciudades (sede del camión) presentes en la flota en vivo, ordenadas.
List<String> fleetCities(List<VehicleLive> vehicles) {
  final cities = <String>{
    for (final v in vehicles)
      if (v.city != null && v.city!.trim().isNotEmpty) v.city!,
  }.toList()..sort();
  return cities;
}
