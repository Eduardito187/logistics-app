import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/app_me_response.dart';
import 'package:logistics_app/core/api/models/app_user_profile.dart';
import 'package:logistics_app/core/auth/biometric/biometric_authenticator.dart';
import 'package:logistics_app/core/auth/biometric/biometric_capabilities.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential_store.dart';
import 'package:logistics_app/core/auth/biometric/biometric_result.dart';
import 'package:logistics_app/core/auth/biometric/biometric_type.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/features/settings/presentation/controllers/settings_controllers.dart';
import 'package:logistics_app/features/settings/presentation/widgets/biometric_login_tile.dart';
import 'package:logistics_app/features/settings/presentation/widgets/profile_section.dart';

import '../../../../core/auth/test_fakes.dart';
import '../../../../support/fake_biometric_authenticator.dart';

// Switch "Ingresar con …" del perfil: oculto sin biometría, deshabilitado con
// instrucción si no hay nada registrado, y activar/desactivar guarda o borra
// la credencial (una sola cuenta por teléfono).

const _email = 'juan.perez@dismac.com';

Future<FakeSecureStorage> _pump(
  WidgetTester tester,
  FakeBiometricAuthenticator auth, {
  FakeSecureStorage? storage,
}) async {
  final store = storage ?? FakeSecureStorage();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        biometricAuthenticatorProvider.overrideWithValue(auth),
        secureStorageProvider.overrideWithValue(store),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: BiometricLoginTile(email: _email, name: 'Juan Pérez'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

const _switchKey = Key('biometricLoginSwitch');

SwitchListTile _switch(WidgetTester tester) =>
    tester.widget<SwitchListTile>(find.byKey(_switchKey));

Future<BiometricCredential?> _saved(FakeSecureStorage storage) =>
    BiometricCredentialStore(storage).read();

void main() {
  testWidgets('teléfono sin biometría: el switch no se muestra', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBiometricAuthenticator(caps: BiometricCapabilities.unsupported),
    );
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.textContaining('Ingresar con'), findsNothing);
  });

  testWidgets('con sensor pero sin registrar: deshabilitado con instrucción', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeBiometricAuthenticator(
        caps: const BiometricCapabilities(
          supported: true,
          enrolled: false,
          types: {BiometricType.fingerprint},
        ),
      ),
    );
    expect(find.text('Ingresar con huella'), findsOneWidget);
    expect(
      find.text(
        'Configurá tu huella en los ajustes del teléfono para usarlo acá.',
      ),
      findsOneWidget,
    );
    expect(_switch(tester).onChanged, isNull);
    expect(_switch(tester).value, isFalse);
  });

  testWidgets('el texto nombra solo lo que el teléfono tiene', (tester) async {
    await _pump(
      tester,
      FakeBiometricAuthenticator(
        caps: const BiometricCapabilities(
          supported: true,
          enrolled: true,
          types: {BiometricType.face},
        ),
      ),
    );
    expect(find.text('Ingresar con reconocimiento facial'), findsOneWidget);
    expect(find.textContaining('huella'), findsNothing);
  });

  testWidgets('activar: pide contraseña y biometría, y guarda la cuenta', (
    tester,
  ) async {
    final auth = FakeBiometricAuthenticator();
    final storage = await _pump(tester, auth);
    expect(_switch(tester).value, isFalse);

    await tester.tap(find.byKey(const Key('biometricLoginSwitch')));
    await tester.pumpAndSettle();
    expect(find.text('Activar huella'), findsOneWidget);
    // Sin otra cuenta guardada no hay aviso de reemplazo.
    expect(find.textContaining('Solo una cuenta'), findsNothing);

    // Vacía: no cierra.
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribí tu contraseña.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('biometricPasswordField')),
      'secreta',
    );
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(auth.authenticateCalls, 1);
    final saved = await _saved(storage);
    expect(saved?.email, _email);
    expect(saved?.password, 'secreta');
    expect(saved?.name, 'Juan Pérez');
    expect(_switch(tester).value, isTrue);
    expect(
      find.text('Listo: la próxima vez ingresá con huella.'),
      findsOneWidget,
    );
  });

  testWidgets('activar con biometría cancelada: no guarda', (tester) async {
    final auth = FakeBiometricAuthenticator(result: BiometricResult.cancelled);
    final storage = await _pump(tester, auth);

    await tester.tap(find.byKey(const Key('biometricLoginSwitch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('biometricPasswordField')),
      'secreta',
    );
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect(await _saved(storage), isNull);
    expect(_switch(tester).value, isFalse);
  });

  testWidgets('cancelar el diálogo de contraseña no pide biometría', (
    tester,
  ) async {
    final auth = FakeBiometricAuthenticator();
    await _pump(tester, auth);

    await tester.tap(find.byKey(const Key('biometricLoginSwitch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(auth.authenticateCalls, 0);
    expect(_switch(tester).value, isFalse);
  });

  testWidgets('otra cuenta guardada: avisa que se reemplaza y la reemplaza', (
    tester,
  ) async {
    final storage = FakeSecureStorage();
    await BiometricCredentialStore(storage).save(
      const BiometricCredential(
        email: 'ana@dismac.com',
        password: 'p',
        name: 'Ana Rojas',
      ),
    );
    await _pump(tester, FakeBiometricAuthenticator(), storage: storage);
    // La credencial es de otra cuenta: para ESTA cuenta está apagado.
    expect(_switch(tester).value, isFalse);

    await tester.tap(find.byKey(const Key('biometricLoginSwitch')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Solo una cuenta puede usar huella en este teléfono: se reemplazará '
        'la de Ana Rojas.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('biometricPasswordField')),
      'secreta',
    );
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();

    expect((await _saved(storage))?.email, _email);
  });

  testWidgets('desactivar borra la credencial', (tester) async {
    final storage = FakeSecureStorage();
    await BiometricCredentialStore(
      storage,
    ).save(const BiometricCredential(email: _email, password: 'secreta'));
    final auth = FakeBiometricAuthenticator();
    await _pump(tester, auth, storage: storage);
    expect(_switch(tester).value, isTrue);

    await tester.tap(find.byKey(const Key('biometricLoginSwitch')));
    await tester.pumpAndSettle();

    expect(await _saved(storage), isNull);
    expect(_switch(tester).value, isFalse);
    expect(auth.authenticateCalls, 0);
    expect(find.text('Se desactivó el ingreso con huella.'), findsOneWidget);
  });

  testWidgets('el perfil incluye el switch con el correo de /me', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appMeProvider.overrideWith(
            (ref) async => const AppMeResponse(
              user: AppUserProfile(
                id: 1,
                name: 'Juan Pérez',
                email: _email,
                roles: ['chofer'],
              ),
              device: null,
              abilities: [],
            ),
          ),
          biometricAuthenticatorProvider.overrideWithValue(
            FakeBiometricAuthenticator(),
          ),
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileSection())),
      ),
    );
    await tester.pumpAndSettle();

    final tile = tester.widget<BiometricLoginTile>(
      find.byType(BiometricLoginTile),
    );
    expect(tile.email, _email);
    expect(tile.name, 'Juan Pérez');
    expect(find.text('Ingresar con huella'), findsOneWidget);
  });
}
