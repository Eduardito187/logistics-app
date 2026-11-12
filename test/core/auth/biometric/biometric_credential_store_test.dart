import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/biometric/biometric_auto_prompt_gate.dart';
import 'package:logistics_app/core/auth/biometric/biometric_authenticator.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential_notifier.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential_store.dart';
import 'package:logistics_app/core/auth/biometric/biometric_result.dart';
import 'package:logistics_app/core/auth/token_store.dart';

import '../../../support/fake_biometric_authenticator.dart';
import '../test_fakes.dart';

// Credencial para ingresar con biometría: una sola cuenta por teléfono, en el
// almacén seguro; "Ahora no" recordado por cuenta; nunca lanza al leer.

const _juan = BiometricCredential(
  email: 'juan.perez@dismac.com',
  password: 'secreta',
  name: 'Juan Pérez',
);

void main() {
  group('BiometricCredential', () {
    test('enmascara el correo', () {
      expect(
        BiometricCredential.maskEmail('juan.perez@dismac.com'),
        'juan.p…@dismac.com',
      );
      expect(BiometricCredential.maskEmail('juan@x.com'), 'ju…@x.com');
      expect(BiometricCredential.maskEmail('a@x.com'), 'a@x.com');
      expect(BiometricCredential.maskEmail('chofer01'), 'chofer…');
    });

    test('displayName: el nombre o el correo enmascarado', () {
      expect(_juan.displayName, 'Juan Pérez');
      expect(
        const BiometricCredential(
          email: 'juan.perez@dismac.com',
          password: 'x',
        ).displayName,
        'juan.p…@dismac.com',
      );
    });

    test('isFor no distingue mayúsculas ni espacios', () {
      expect(_juan.isFor(' JUAN.PEREZ@dismac.com '), isTrue);
      expect(_juan.isFor('ana@dismac.com'), isFalse);
    });

    test('toString no expone la contraseña', () {
      expect(_juan.toString(), isNot(contains('secreta')));
    });

    test('JSON ida y vuelta; incompleto → null', () {
      expect(BiometricCredential.fromJson(_juan.toJson()), _juan);
      expect(BiometricCredential.fromJson({'email': 'x@y.com'}), isNull);
      expect(BiometricCredential.fromJson({'password': 'x'}), isNull);
    });
  });

  group('BiometricCredentialStore', () {
    test('guarda, lee y borra', () async {
      final storage = FakeSecureStorage();
      final store = BiometricCredentialStore(storage);
      expect(await store.read(), isNull);

      await store.save(_juan);
      expect(await store.read(), _juan);
      expect(storage.data[BiometricCredentialStore.credentialKey], isNotNull);

      await store.clear();
      expect(await store.read(), isNull);
    });

    test('una sola cuenta: guardar otra reemplaza', () async {
      final store = BiometricCredentialStore(FakeSecureStorage());
      await store.save(_juan);
      const ana = BiometricCredential(email: 'ana@dismac.com', password: 'p');
      await store.save(ana);
      expect(await store.read(), ana);
    });

    test('dato corrupto → sin credencial (no lanza)', () async {
      final storage = FakeSecureStorage()
        ..seed(BiometricCredentialStore.credentialKey, '{no es json');
      expect(await BiometricCredentialStore(storage).read(), isNull);
    });

    test('borrar con almacén fallando no lanza', () async {
      final storage = FakeSecureStorage(throwOnDelete: true);
      await BiometricCredentialStore(storage).clear();
    });

    test('"Ahora no" se recuerda por cuenta', () async {
      final storage = FakeSecureStorage();
      final store = BiometricCredentialStore(storage);
      expect(await store.hasDeclined('juan@x.com'), isFalse);

      await store.markDeclined(' JUAN@x.com');
      expect(await store.hasDeclined('juan@x.com'), isTrue);
      expect(await store.hasDeclined('ana@x.com'), isFalse);
      expect(jsonDecode(storage.data[BiometricCredentialStore.declinedKey]!), [
        'juan@x.com',
      ]);

      await store.clearDeclined('juan@x.com');
      expect(await store.hasDeclined('juan@x.com'), isFalse);
    });
  });

  group('BiometricCredentialNotifier', () {
    late FakeSecureStorage storage;
    late FakeBiometricAuthenticator auth;
    late ProviderContainer container;

    setUp(() {
      storage = FakeSecureStorage();
      auth = FakeBiometricAuthenticator();
      container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          biometricAuthenticatorProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
    });

    BiometricCredentialStore store() =>
        container.read(biometricCredentialStoreProvider);

    test('enable: pide la biometría y guarda la credencial', () async {
      await store().markDeclined(_juan.email);
      final result = await container
          .read(biometricCredentialProvider.notifier)
          .enable(
            email: _juan.email,
            password: _juan.password,
            name: _juan.name,
            capabilities: kFingerprintReady,
          );

      expect(result, BiometricResult.success);
      expect(auth.authenticateCalls, 1);
      expect(auth.lastReason, 'Confirmá tu huella para activarlo');
      expect(await store().read(), _juan);
      expect(container.read(biometricCredentialProvider).value, _juan);
      // Activarla olvida el "Ahora no" previo.
      await Future<void>.delayed(Duration.zero);
      expect(await store().hasDeclined(_juan.email), isFalse);
    });

    test('enable cancelado: no guarda nada', () async {
      auth.result = BiometricResult.cancelled;
      final result = await container
          .read(biometricCredentialProvider.notifier)
          .enable(
            email: _juan.email,
            password: _juan.password,
            capabilities: kFingerprintReady,
          );
      expect(result, BiometricResult.cancelled);
      expect(await store().read(), isNull);
    });

    test('disable borra la credencial', () async {
      await store().save(_juan);
      expect(await container.read(biometricCredentialProvider.future), _juan);

      await container.read(biometricCredentialProvider.notifier).disable();
      expect(container.read(biometricCredentialProvider).value, isNull);
      expect(await store().read(), isNull);
    });

    test('syncPassword actualiza solo la misma cuenta', () async {
      await store().save(_juan);
      final notifier = container.read(biometricCredentialProvider.notifier);

      await notifier.syncPassword(email: 'ana@dismac.com', password: 'otra');
      expect((await store().read())?.password, 'secreta');

      await notifier.syncPassword(email: _juan.email, password: 'nueva');
      expect((await store().read())?.password, 'nueva');
      expect(
        container.read(biometricCredentialProvider).value?.name,
        'Juan Pérez',
      );
    });
  });

  group('BiometricAutoPromptGate', () {
    test('solo la primera vez', () {
      final gate = BiometricAutoPromptGate();
      expect(gate.consume(), isTrue);
      expect(gate.consume(), isFalse);
    });

    test('suprimido (logout manual) no lanza nunca', () {
      final gate = BiometricAutoPromptGate()..suppress();
      expect(gate.consume(), isFalse);
    });
  });
}
