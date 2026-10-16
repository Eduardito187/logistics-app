import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/location/gps_fix.dart';

// GpsFix es un modelo de datos simple: solo se verifica que guarde sus campos y
// que `accuracy` sea opcional (null por defecto).
void main() {
  group('GpsFix', () {
    test('guarda lat/lng/accuracy', () {
      const fix = GpsFix(lat: -16.5, lng: -68.15, accuracy: 4.2);
      expect(fix.lat, -16.5);
      expect(fix.lng, -68.15);
      expect(fix.accuracy, 4.2);
    });

    test('accuracy es opcional y nace en null', () {
      const fix = GpsFix(lat: 0, lng: 0);
      expect(fix.accuracy, isNull);
    });
  });
}
