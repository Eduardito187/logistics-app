import 'gps_fix.dart';

/// Estado observable del rastreo en vivo del camión, para que la UI muestre si
/// está activo, a qué envío se asocia y cuántas posiciones se enviaron.
class TruckTrackingState {
  const TruckTrackingState({
    this.active = false,
    this.shipmentId,
    this.sent = 0,
    this.lastFix,
  });

  final bool active;
  final String? shipmentId;
  final int sent;
  final GpsFix? lastFix;

  /// Centinela para poder limpiar los campos nullables a null (al detener el
  /// rastreo hay que soltar `shipmentId`/`lastFix`). Con `x ?? this.x` un
  /// `copyWith(shipmentId: null)` conservaba el valor viejo.
  static const Object _unset = Object();

  TruckTrackingState copyWith({
    bool? active,
    Object? shipmentId = _unset,
    int? sent,
    Object? lastFix = _unset,
  }) {
    return TruckTrackingState(
      active: active ?? this.active,
      shipmentId: identical(shipmentId, _unset)
          ? this.shipmentId
          : shipmentId as String?,
      sent: sent ?? this.sent,
      lastFix: identical(lastFix, _unset) ? this.lastFix : lastFix as GpsFix?,
    );
  }
}
