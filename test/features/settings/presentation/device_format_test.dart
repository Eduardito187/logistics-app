import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logistics_app/features/settings/presentation/device_format.dart';

// Formateadores de dispositivos/sesiones. formatDeviceDateTime usa locale 'es',
// que hay que inicializar en el test (la app lo hace en main()).

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('platformLabel', () {
    test('mapea las plataformas conocidas', () {
      expect(platformLabel('android'), 'Android');
      expect(platformLabel('ios'), 'iOS');
      expect(platformLabel('web'), 'Web');
    });

    test('es insensible a mayúsculas en las conocidas', () {
      expect(platformLabel('ANDROID'), 'Android');
      expect(platformLabel('iOS'), 'iOS');
    });

    test('null o vacío cae a "Dispositivo"', () {
      expect(platformLabel(null), 'Dispositivo');
      expect(platformLabel(''), 'Dispositivo');
    });

    test('una plataforma desconocida se devuelve tal cual', () {
      expect(platformLabel('windows'), 'windows');
      expect(platformLabel('KaiOS'), 'KaiOS');
    });
  });

  group('formatDeviceDateTime', () {
    test('null se muestra como guion', () {
      expect(formatDeviceDateTime(null), '—');
    });

    test('una fecha se formatea en es con día, año y hora', () {
      // Fecha local (sin desfase por toLocal en el test).
      final result = formatDeviceDateTime(DateTime(2026, 3, 5, 14, 30));
      expect(result, isNot('—'));
      expect(result, contains('2026'));
      expect(result, contains('14:30'));
      expect(result, startsWith('05'));
    });
  });
}
