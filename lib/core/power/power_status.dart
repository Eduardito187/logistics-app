/// Estado de energía del teléfono: nivel de batería, si está cargando y si el
/// ahorro de energía del sistema (Android "Ahorro de batería" / iOS "Modo de
/// bajo consumo") está activo.
///
/// Con [shouldSaveEnergy] la app gasta menos: GPS más espaciado, sin
/// animaciones decorativas y menos consultas periódicas.
class PowerStatus {
  const PowerStatus({
    this.level,
    this.charging = false,
    this.powerSave = false,
  });

  /// Estado desconocido (tests, escritorio, canal nativo ausente): la app se
  /// comporta normal, sin recortes.
  static const PowerStatus unknown = PowerStatus();

  /// Por debajo de este nivel (%), sin cargar, se considera batería baja.
  static const int lowBatteryThreshold = 20;

  /// Nivel 0–100, o `null` si no se pudo leer.
  final int? level;

  /// Conectado a la corriente (cargando o lleno).
  final bool charging;

  /// Ahorro de energía del sistema activo.
  final bool powerSave;

  /// Batería baja: menos de [lowBatteryThreshold] y sin cargar.
  bool get isLowBattery =>
      !charging && level != null && level! < lowBatteryThreshold;

  /// La app debe recortar su consumo (ahorro del sistema o batería baja).
  bool get shouldSaveEnergy => powerSave || isLowBattery;

  /// Lee la respuesta del canal nativo (`{level, charging, powerSave}`).
  /// Valores ausentes o fuera de rango → desconocidos (nunca lanza).
  factory PowerStatus.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return unknown;
    final rawLevel = map['level'];
    final level = rawLevel is num ? rawLevel.round() : null;
    return PowerStatus(
      level: level != null && level >= 0 && level <= 100 ? level : null,
      charging: map['charging'] == true,
      powerSave: map['powerSave'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PowerStatus &&
      other.level == level &&
      other.charging == charging &&
      other.powerSave == powerSave;

  @override
  int get hashCode => Object.hash(level, charging, powerSave);

  @override
  String toString() =>
      'PowerStatus(level: $level, charging: $charging, powerSave: $powerSave)';
}
