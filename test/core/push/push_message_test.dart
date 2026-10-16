import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/push_message.dart';

// PushMessage es el contenido ya normalizado de un push. Modelo simple.
void main() {
  test('guarda title/body y payload opcional', () {
    const msg = PushMessage(
      title: 'Operación',
      body: 'Nueva ruta',
      payload: 'SHP-1',
    );
    expect(msg.title, 'Operación');
    expect(msg.body, 'Nueva ruta');
    expect(msg.payload, 'SHP-1');
  });

  test('payload es opcional (null por defecto)', () {
    const msg = PushMessage(title: 't', body: 'b');
    expect(msg.payload, isNull);
  });
}
