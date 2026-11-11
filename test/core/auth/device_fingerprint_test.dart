import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/device_fingerprint.dart';

// Huella por instalación + usuario: evita que otro usuario en el mismo
// teléfono reasigne la fila del dispositivo (bug "dispositivo dado de baja").

void main() {
  const install = '01M75QZBMWQEXAMPLE';

  test('mismo usuario y misma instalación → misma huella (estable)', () async {
    final a = await userDeviceFingerprint(installId: install, email: 'a@x.com');
    final b = await userDeviceFingerprint(installId: install, email: 'a@x.com');
    expect(a, b);
  });

  test('normaliza mayúsculas y espacios del email', () async {
    final a = await userDeviceFingerprint(installId: install, email: 'a@x.com');
    final b = await userDeviceFingerprint(
      installId: install,
      email: '  A@X.COM ',
    );
    expect(a, b);
  });

  test('otro usuario en el mismo teléfono → huella distinta', () async {
    final a = await userDeviceFingerprint(installId: install, email: 'a@x.com');
    final b = await userDeviceFingerprint(installId: install, email: 'b@x.com');
    expect(a, isNot(b));
  });

  test('mismo usuario en otra instalación → huella distinta', () async {
    final a = await userDeviceFingerprint(installId: install, email: 'a@x.com');
    final b = await userDeviceFingerprint(installId: 'OTRA', email: 'a@x.com');
    expect(a, isNot(b));
  });

  test('formato: <installId>-u<16 hex>, sin el email en claro', () async {
    final fp = await userDeviceFingerprint(
      installId: install,
      email: 'chofer@dismac.com',
    );
    expect(fp, matches(RegExp('^$install-u[0-9a-f]{16}\$')));
    expect(fp.contains('chofer'), isFalse);
    expect(fp.length, lessThanOrEqualTo(255)); // tope del backend
  });
}
