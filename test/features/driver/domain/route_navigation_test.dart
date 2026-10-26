import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:logistics_app/features/driver/domain/entities/route_navigation.dart';

// Navegación dentro de "Entrega en curso": distancia/tiempo restantes (sobre
// el trazo por calles o línea recta × factor) y aviso "Fuera de ruta".

const _distance = Distance();

// Trazo en "L" hacia el este y luego al norte (Santa Cruz), ~1,1 km + ~1,1 km.
const _a = LatLng(-17.790, -63.190);
const _b = LatLng(-17.790, -63.180);
const _c = LatLng(-17.780, -63.180);
const _line = [_a, _b, _c];

void main() {
  group('distanceToPolylineMeters', () {
    test('sobre el trazo es ~0 y a un costado mide la perpendicular', () {
      expect(
        distanceToPolylineMeters(const LatLng(-17.790, -63.185), _line),
        lessThan(1),
      );
      // 0,002° de latitud ≈ 221 m al sur del primer tramo.
      final d = distanceToPolylineMeters(
        const LatLng(-17.792, -63.185),
        _line,
      )!;
      expect(d, closeTo(221, 5));
    });

    test('sin trazo (menos de 2 puntos) devuelve null', () {
      expect(distanceToPolylineMeters(_a, const []), isNull);
      expect(distanceToPolylineMeters(_a, const [_a]), isNull);
    });
  });

  group('estimateRemaining', () {
    test('sin trazo: línea recta × factor y velocidad urbana por defecto', () {
      final e = estimateRemaining(from: _a, to: _b);
      final straight = _distance(_a, _b);
      expect(e.alongRoute, isFalse);
      expect(e.offRoute, isFalse);
      expect(e.meters, closeTo(straight * kStraightLineDetourFactor, 0.01));
      expect(e.duration.inSeconds, (e.meters / kDefaultUrbanSpeedMps).round());
    });

    test('con trazo: mide sobre las calles, no en línea recta', () {
      final e = estimateRemaining(
        from: _a,
        to: _c,
        geometry: _line,
        geometryMeters: 2000,
        geometrySeconds: 400, // 5 m/s
      );
      final along = _distance(_a, _b) + _distance(_b, _c);
      expect(e.alongRoute, isTrue);
      expect(e.offRoute, isFalse);
      expect(e.meters, closeTo(along, 1));
      // Más que la diagonal: va por la "L".
      expect(e.meters, greaterThan(_distance(_a, _c)));
      expect(e.duration.inSeconds, (e.meters / 5).round());
    });

    test('desde la mitad del trazo cuenta solo lo que falta', () {
      const mid = LatLng(-17.790, -63.185);
      final e = estimateRemaining(from: mid, to: _c, geometry: _line);
      final expected = _distance(mid, _b) + _distance(_b, _c);
      expect(e.meters, closeTo(expected, 2));
    });

    test('a más de 150 m del trazo: "Fuera de ruta" y línea recta', () {
      const away = LatLng(-17.795, -63.185); // ~550 m al sur
      final e = estimateRemaining(from: away, to: _c, geometry: _line);
      expect(e.offRoute, isTrue);
      expect(e.alongRoute, isFalse);
      expect(
        e.meters,
        closeTo(_distance(away, _c) * kStraightLineDetourFactor, 0.01),
      );
    });

    test('a menos de 150 m del trazo no avisa', () {
      const near = LatLng(-17.7905, -63.185); // ~55 m
      final e = estimateRemaining(from: near, to: _c, geometry: _line);
      expect(e.offRoute, isFalse);
      expect(e.alongRoute, isTrue);
    });

    test('parada "atrás" en el trazo: cae a línea recta', () {
      const ahead = LatLng(-17.790, -63.182);
      final e = estimateRemaining(from: ahead, to: _a, geometry: _line);
      expect(e.alongRoute, isFalse);
      expect(e.offRoute, isFalse);
    });
  });

  group('formato', () {
    test('distancia en metros redondeados o km con coma', () {
      expect(formatDistance(347), '350 m');
      expect(formatDistance(4210), '4,2 km');
      expect(formatDistance(12600), '13 km');
    });

    test('tiempo en minutos u horas', () {
      expect(formatRemainingTime(const Duration(seconds: 20)), '< 1 min');
      expect(formatRemainingTime(const Duration(minutes: 12)), '12 min');
      expect(formatRemainingTime(const Duration(minutes: 65)), '1 h 05 min');
    });
  });

  group('simplifyPolyline', () {
    test('con menos de 3 puntos devuelve la misma lista', () {
      const two = [_a, _b];
      expect(identical(simplifyPolyline(two), two), isTrue);
    });

    test(
      'quita los puntos intermedios de una recta y conserva las esquinas',
      () {
        final dense = [
          for (var i = 0; i <= 100; i++) LatLng(-17.790, -63.190 + i * 0.0001),
          for (var i = 1; i <= 100; i++) LatLng(-17.790 + i * 0.0001, -63.180),
        ];
        final simple = simplifyPolyline(dense);
        expect(simple, hasLength(3));
        expect(simple.first, dense.first);
        expect(simple[1].longitude, closeTo(-63.180, 1e-9));
        expect(simple.last, dense.last);
      },
    );

    test(
      'un zigzag menor a la tolerancia se aplana; uno mayor se conserva',
      () {
        // ~1 m de desvío (0.00001°) vs ~55 m (0.0005°).
        const small = [
          LatLng(-17.790, -63.190),
          LatLng(-17.78999, -63.189),
          LatLng(-17.790, -63.188),
        ];
        const big = [
          LatLng(-17.790, -63.190),
          LatLng(-17.7895, -63.189),
          LatLng(-17.790, -63.188),
        ];
        expect(simplifyPolyline(small), hasLength(2));
        expect(simplifyPolyline(big), hasLength(3));
      },
    );

    test('la distancia sobre el trazo simplificado es la real', () {
      final dense = [
        for (var i = 0; i <= 100; i++) LatLng(-17.790, -63.190 + i * 0.0001),
        for (var i = 1; i <= 100; i++) LatLng(-17.790 + i * 0.0001, -63.180),
      ];
      const from = LatLng(-17.790, -63.188);
      const corner = LatLng(-17.790, -63.180);
      final exact = _distance(from, corner) + _distance(corner, _c);
      final simple = estimateRemaining(
        from: from,
        to: _c,
        geometry: simplifyPolyline(dense),
      );
      expect(simple.alongRoute, isTrue);
      // `Distance` redondea cada tramo al metro: con 200 tramos el trazo
      // denso acumula error; el simplificado (2 tramos) queda casi exacto.
      expect(simple.meters, closeTo(exact, 2));
    });
  });
}
