import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mueve o hace zoom del mapa con una transición suave.
///
/// `MapController.move` de flutter_map es INSTANTÁNEO: al tocar + / − el mapa
/// salta y los tiles se ven cortarse. Este ayudante interpola centro y zoom con
/// un único [AnimationController] reutilizable (cancela la animación anterior si
/// se vuelve a tocar) para que el acercar/alejar se sienta fluido. Con
/// reduce-motion salta directo, sin animar.
///
/// Uso: crear uno por `State` (con `vsync: this`), llamar [animateTo] y
/// [dispose] al desmontar.
class AnimatedMapMover {
  AnimatedMapMover({
    required TickerProvider vsync,
    required this.controller,
    Duration duration = const Duration(milliseconds: 320),
  }) : _anim = AnimationController(vsync: vsync, duration: duration) {
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.addListener(_tick);
  }

  final MapController controller;
  final AnimationController _anim;
  late final CurvedAnimation _curve;

  /// `true` mientras hay una animación de cámara en curso: el auto-enfoque no
  /// debe pisar un acercar/alejar o un seguimiento que recién arrancó.
  bool get isAnimating => _anim.isAnimating;

  LatLng _fromCenter = const LatLng(0, 0);
  LatLng _toCenter = const LatLng(0, 0);
  double _fromZoom = 0;
  double _toZoom = 0;

  /// Zoom "pendiente": el destino de la animación en curso (o `null` si no hay
  /// ninguna). Los toques rápidos de +/− se acumulan sobre ESTE valor y no
  /// sobre el zoom a medio animar, así tocar "−" dos veces seguidas baja dos
  /// niveles (y no se queda en uno por leer un valor intermedio).
  double? _pendingZoom;

  void _tick() {
    final t = _curve.value;
    final center = LatLng(
      _fromCenter.latitude + (_toCenter.latitude - _fromCenter.latitude) * t,
      _fromCenter.longitude + (_toCenter.longitude - _fromCenter.longitude) * t,
    );
    controller.move(center, _fromZoom + (_toZoom - _fromZoom) * t);
    if (t >= 1) _pendingZoom = null;
  }

  /// Anima la cámara hasta [center]/[zoom]. Con [reduceMotion] salta directo.
  void animateTo(LatLng center, double zoom, {required bool reduceMotion}) {
    _pendingZoom = zoom;
    if (reduceMotion) {
      controller.move(center, zoom);
      _pendingZoom = null;
      return;
    }
    _fromCenter = controller.camera.center;
    _fromZoom = controller.camera.zoom;
    _toCenter = center;
    _toZoom = zoom;
    _anim.forward(from: 0);
  }

  /// Acerca/aleja [delta] niveles sobre el centro actual, acumulando sobre el
  /// zoom pendiente (toques rápidos) y recortando a [min]/[max].
  void zoomBy(
    double delta, {
    required double min,
    required double max,
    required bool reduceMotion,
  }) {
    final base = _pendingZoom ?? controller.camera.zoom;
    final zoom = (base + delta).clamp(min, max);
    animateTo(controller.camera.center, zoom, reduceMotion: reduceMotion);
  }

  void dispose() {
    _anim.removeListener(_tick);
    _curve.dispose();
    _anim.dispose();
  }
}
