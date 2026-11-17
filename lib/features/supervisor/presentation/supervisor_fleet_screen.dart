import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/vehicle_live.dart';
import '../../../core/icons/icons.dart';
import '../../../core/power/power_status_notifier.dart';
import '../../../core/realtime/pusher_socket.dart';
import '../../../core/realtime/realtime_bus.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/empty_state.dart';
import 'controllers/supervisor_controllers.dart';
import 'widgets/fleet_map.dart';

/// RESPALDO sin tiempo real: cada cuánto se piden de nuevo las posiciones de
/// la flota mientras la pantalla está a la vista. 30 s: la telemetría no cambia más rápido de forma
/// útil para el supervisor y en un teléfono de 1 GB cada refresco cuesta red,
/// JSON y un reagrupado del mapa.
const Duration fleetRefreshInterval = Duration(seconds: 30);

/// Intervalo con ahorro de energía o batería < 20 % (menos radio y CPU).
const Duration fleetRefreshIntervalSaving = Duration(seconds: 90);

/// Flota en vivo: mapa OSM con la última posición conocida de cada camión.
///
/// Las posiciones llegan EN TIEMPO REAL por socket (evento `fleet.position`,
/// se aplica sobre la lista sin volver a pedirla; `fleet.removed` quita un
/// camión dado de baja). Solo si no hay socket se
/// refresca cada [fleetRefreshInterval]. La escucha y el refresco se
/// **detienen**:
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

  /// Deja de escuchar el tema de flota (`null` = no está escuchando).
  void Function()? _stopRealtime;

  /// Las posiciones están llegando por socket.
  bool _live = false;

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
    _live = ref.read(realtimeTopicLiveProvider(RealtimeTopic.fleet));
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
    _stopRealtime?.call();
    _stopRealtime = null;
    super.dispose();
  }

  static bool _isActive(AppLifecycleState state) =>
      state == AppLifecycleState.resumed || state == AppLifecycleState.inactive;

  /// Arranca o detiene la escucha en tiempo real y el refresco de respaldo
  /// según la visibilidad y el estado de la app.
  void _syncPolling({required bool refreshNow}) {
    final shouldRun = _appActive && (_visible ?? false);
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      _stopRealtime?.call();
      _stopRealtime = null;
      return;
    }
    _stopRealtime ??= ref
        .read(realtimeBusProvider)
        .listen(RealtimeTopic.fleet, _onFleetEvent);
    // En una microtarea (al terminar el frame en curso): Riverpod pausa las
    // suscripciones de una ruta tapada y las reanuda en el build, que corre
    // después de `didChangeDependencies`; invalidar antes se perdía.
    if (refreshNow) scheduleMicrotask(_refresh);
    if (_live) {
      // Con socket no se refresca por tiempo.
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (_timer != null) return;
    final saving = ref.read(powerStatusProvider).shouldSaveEnergy;
    _timer = Timer.periodic(
      saving ? fleetRefreshIntervalSaving : fleetRefreshInterval,
      (_) => _refresh(),
    );
  }

  /// Posición nueva de un camión: se aplica sobre la lista, sin pedirla.
  void _onFleetEvent(RealtimeEvent event) {
    if (!mounted) return;
    switch (event.name) {
      case 'fleet.position':
        try {
          ref
              .read(fleetLiveProvider.notifier)
              .apply(VehicleLive.fromJson(event.data));
        } on Object {
          // Evento incompleto: se pide la lista entera.
          _refresh();
        }
      case 'fleet.removed':
        final vehicleId = event.data['vehicle_id'];
        if (vehicleId is String) {
          ref.read(fleetLiveProvider.notifier).remove(vehicleId);
        }
    }
  }

  void _refresh() {
    if (!mounted) return;
    // Sin pedidos solapados: si el anterior no volvió, se espera al próximo.
    if (ref.read(fleetLiveProvider).isLoading) return;
    ref.invalidate(fleetLiveProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Se conectó (o se cayó) el socket: al conectar se pide una vez, por lo
    // que se haya perdido; al caerse vuelve el refresco de respaldo.
    ref.listen(realtimeTopicLiveProvider(RealtimeTopic.fleet), (_, live) {
      _live = live;
      _syncPolling(refreshNow: live);
    });
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: DropdownButtonFormField<String?>(
                    value: city,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(
                        child: Text('Todo el país · ${vehicles.length}'),
                      ),
                      for (final name in cities)
                        DropdownMenuItem(
                          value: name,
                          child: Text(
                            '$name · '
                            '${vehicles.where((v) => v.city == name).length}',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _city = value),
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
}

/// Ciudades (sede del camión) presentes en la flota en vivo, ordenadas.
List<String> fleetCities(List<VehicleLive> vehicles) {
  final cities = <String>{
    for (final v in vehicles)
      if (v.city != null && v.city!.trim().isNotEmpty) v.city!,
  }.toList()..sort();
  return cities;
}
