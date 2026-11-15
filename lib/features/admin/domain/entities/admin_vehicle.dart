/// Estado operativo de un camión (`status` del backend).
enum AdminVehicleStatus {
  available('available', 'Disponible'),
  inService('in_service', 'En servicio'),
  maintenance('maintenance', 'En mantenimiento'),
  inactive('inactive', 'Inactivo'),
  unknown('', 'Sin estado');

  const AdminVehicleStatus(this.wire, this.label);

  /// Valor que viaja al backend (filtro `status`).
  final String wire;

  /// Texto en español para la UI.
  final String label;

  static AdminVehicleStatus fromWire(String? raw) => values.firstWhere(
    (s) => s.wire == raw,
    orElse: () => AdminVehicleStatus.unknown,
  );
}

/// Un camión de la flota tal como lo ve el administrador. Modelo mínimo de UI,
/// leído del JSON de `GET /app/fleet/vehicles` (la búsqueda y la paginación de
/// ese endpoint todavía no están en el cliente generado).
class AdminVehicle {
  const AdminVehicle({
    required this.id,
    required this.status,
    this.plate,
    this.capacityKg,
    this.homeBaseNodeId,
    this.fitToDispatch,
    this.unfitReason,
  });

  factory AdminVehicle.fromJson(Map<String, Object?> json) => AdminVehicle(
    id: '${json['id']}',
    plate: json['plate'] as String?,
    status: AdminVehicleStatus.fromWire(json['status'] as String?),
    capacityKg: (json['capacity_kg'] as num?)?.toInt(),
    homeBaseNodeId: json['home_base_node_id'] as String?,
    fitToDispatch: json['fit_to_dispatch'] as bool?,
    unfitReason: json['unfit_reason'] as String?,
  );

  final String id;
  final String? plate;
  final AdminVehicleStatus status;
  final int? capacityKg;
  final String? homeBaseNodeId;

  /// `false` si el camión quedó NO apto para salir (inspección crítica).
  final bool? fitToDispatch;
  final String? unfitReason;

  /// Placa o, si no tiene, un texto neutro (nunca el uuid).
  String get displayPlate => plate ?? 'Sin placa';
}
