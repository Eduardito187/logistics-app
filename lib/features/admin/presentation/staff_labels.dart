import '../../../core/api/export.dart';
import '../../../core/auth/user_role.dart';

/// Etiqueta en español de un rol del backend (`chofer` → "Chofer").
String staffRoleLabel(String key) => UserRole.fromBackendKey(key)?.label ?? key;

/// Roles de una persona en una línea ("Chofer · Supervisor").
String staffRolesText(List<String>? roles) {
  if (roles == null || roles.isEmpty) return 'Sin rol';
  return roles.map(staffRoleLabel).join(' · ');
}

/// `true` si la persona es chofer (tiene ficha de chofer: licencia y camión).
bool staffIsDriver(String? driverId, List<String>? roles) =>
    driverId != null || (roles?.contains(UserRole.driver.backendKey) ?? false);

/// Cara de un documento de dos caras, o `null` si es de una sola.
String? staffSideLabel(StaffDocumentSide? side) => switch (side) {
  StaffDocumentSide.front => 'Anverso',
  StaffDocumentSide.back => 'Reverso',
  _ => null,
};

/// `true` si la persona trabaja en una tienda (solo a ella se le asigna una).
bool staffIsStore(List<String>? roles) =>
    roles?.contains(UserRole.store.backendKey) ?? false;

/// Fecha corta `dd/MM/yyyy` en hora local.
String staffDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}';
}

/// Fecha y hora corta `dd/MM/yyyy HH:mm` en hora local.
String staffDateTime(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${staffDate(date)} ${two(d.hour)}:${two(d.minute)}';
}

/// Título en español de un hecho del historial. El backend manda un código
/// estable en `title`; lo que no se conoce se muestra legible, sin guiones.
String staffActivityTitle(StaffActivity activity) {
  final code = activity.title ?? '';
  final known = _activityTitles[code];
  if (known != null) return known;
  if (code.isEmpty) return _typeFallback(activity.type);
  final text = code.replaceAll('_', ' ').trim();
  return text[0].toUpperCase() + text.substring(1);
}

String _typeFallback(StaffActivityType? type) => switch (type) {
  StaffActivityType.scan => 'Escaneo',
  StaffActivityType.assignment => 'Asignación',
  StaffActivityType.checklist => 'Inspección',
  StaffActivityType.device => 'Dispositivo',
  _ => 'Actividad',
};

const Map<String, String> _activityTitles = {
  'vehicle_assigned': 'Camión asignado',
  'checklist_passed': 'Inspección aprobada',
  'checklist_failed': 'Inspección con fallas',
  'device_last_seen': 'Última conexión del teléfono',
  'load': 'Carga al camión',
  'unload': 'Descarga',
  'preparation': 'Preparación de pedido',
  'proof_of_delivery': 'Entrega registrada',
  'failed_delivery': 'Entrega fallida',
  'node_reception': 'Recepción en tienda',
  'store_drop': 'Entrega en tienda',
  'LOAD': 'Carga al camión',
  'UNLOAD': 'Descarga',
  'PREPARATION': 'Preparación de pedido',
  'PROOF_OF_DELIVERY': 'Entrega registrada',
  'FAILED_DELIVERY': 'Entrega fallida',
  'NODE_RECEPTION': 'Recepción en tienda',
};

/// Nombre legible del tipo de documento (texto libre del backend).
String staffDocumentTitle(StaffDocument document) {
  final type = (document.documentType ?? '').trim();
  if (type.isEmpty) return 'Documento';
  final text = type.replaceAll('_', ' ');
  return text[0].toUpperCase() + text.substring(1);
}

/// Los nueve departamentos (ciudades) donde se asigna al personal.
const List<Department> staffDepartments = [
  Department.laPaz,
  Department.santaCruz,
  Department.cochabamba,
  Department.oruro,
  Department.potosi,
  Department.chuquisaca,
  Department.tarija,
  Department.beni,
  Department.pando,
];

/// Nombre legible de un departamento.
String departmentLabel(Department department) => switch (department) {
  Department.laPaz => 'La Paz',
  Department.santaCruz => 'Santa Cruz',
  Department.cochabamba => 'Cochabamba',
  Department.oruro => 'Oruro',
  Department.potosi => 'Potosí',
  Department.chuquisaca => 'Chuquisaca',
  Department.tarija => 'Tarija',
  Department.beni => 'Beni',
  Department.pando => 'Pando',
  Department.$unknown => 'Otra',
};

/// Departamento de un código del backend (`santa_cruz`), o `null`.
Department? departmentOf(String? code) {
  if (code == null) return null;
  for (final department in staffDepartments) {
    if (department.json == code) return department;
  }
  return null;
}
