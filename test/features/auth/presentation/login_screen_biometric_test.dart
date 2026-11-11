import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/biometric/biometric_auto_prompt_gate.dart';
import 'package:logistics_app/core/auth/biometric/biometric_authenticator.dart';
import 'package:logistics_app/core/auth/biometric/biometric_capabilities.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential.dart';
import 'package:logistics_app/core/auth/biometric/biometric_credential_store.dart';
import 'package:logistics_app/core/auth/biometric/biometric_result.dart';
import 'package:logistics_app/core/auth/biometric/biometric_type.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/auth/domain/entities/login_result.dart';
import 'package:logistics_app/features/auth/domain/entities/two_factor_enrollment.dart';
import 'package:logistics_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';
import 'package:logistics_app/features/auth/presentation/controllers/biometric_offer_context.dart';
import 'package:logistics_app/features/auth/presentation/login_screen.dart';

import '../../../core/auth/test_fakes.dart';
import '../../../support/button_finders.dart';
import '../../../support/fake_biometric_authenticator.dart';
import '../../../support/screen_sizes.dart';

// Ingreso con biometría en el login: el botón aparece solo con credencial
// guardada y biometría utilizable; al tocarlo hace el MISMO login con la
// credencial; contraseña vencida → se borra y se avisa; lanzamiento automático
// solo la primera vez; y la oferta post-login con contraseña.

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error});

  Object? error;
  int loginCalls = 0;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (error != null) throw error!;
    return const LoginSignedIn();
  }

  @override
  Future<void> verifyTwoFactor({
    required String challengeId,
    required String code,
  }) async {}

  @override
  Future<TwoFactorEnrollment> enrollTwoFactor() => throw UnimplementedError();

  @override
  Future<void> confirmTwoFactor(String code) async {}

  @override
  Future<void> disableTwoFactor({String? code, String? password}) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {}
}

const _saved = BiometricCredential(
  email: 'juan.perez@dismac.com',
  password: 'guardada',
  name: 'Juan Pérez',
);

const _biometricButton = Key('biometricSignInButton');

Future<FakeSecureStorage> _seeded({BiometricCredential? credential}) async {
  final storage = FakeSecureStorage();
  if (credential != null) {
    await BiometricCredentialStore(storage).save(credential);
  }
  return storage;
}

/// Login con dobles. [autoPrompt] = es la primera apertura (lanza solo).
/// [offerContext] = dónde mostrar la oferta post-login (el propio test).
Future<void> _pump(
  WidgetTester tester, {
  required _FakeAuthRepository repo,
  required FakeBiometricAuthenticator auth,
  required FakeSecureStorage storage,
  bool autoPrompt = false,
  BuildContext? Function()? offerContext,
  bool textScale = false,
}) async {
  final gate = BiometricAutoPromptGate();
  if (!autoPrompt) gate.suppress();
  const screen = LoginScreen();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        signInProvider.overrideWithValue(SignIn(repo)),
        biometricAuthenticatorProvider.overrideWithValue(auth),
        secureStorageProvider.overrideWithValue(storage),
        biometricAutoPromptGateProvider.overrideWithValue(gate),
        biometricOfferContextProvider.overrideWithValue(
          () async => offerContext?.call(),
        ),
      ],
      child: MaterialApp(home: textScale ? withTextScale(screen) : screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin credencial guardada: no hay botón de biometría', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: _FakeAuthRepository(),
      auth: FakeBiometricAuthenticator(),
      storage: await _seeded(),
    );
    expect(find.byKey(_biometricButton), findsNothing);
    expect(find.textContaining('Ingresar con'), findsNothing);
  });

  testWidgets('con credencial pero el teléfono ya no tiene biometría '
      'registrada: no hay botón', (tester) async {
    await _pump(
      tester,
      repo: _FakeAuthRepository(),
      auth: FakeBiometricAuthenticator(
        caps: const BiometricCapabilities(
          supported: true,
          enrolled: false,
          types: {BiometricType.fingerprint},
        ),
      ),
      storage: await _seeded(credential: _saved),
    );
    expect(find.byKey(_biometricButton), findsNothing);
  });

  testWidgets('con credencial: botón "Ingresar con huella" y la cuenta', (
    tester,
  ) async {
    await _pump(
      tester,
      repo: _FakeAuthRepository(),
      auth: FakeBiometricAuthenticator(),
      storage: await _seeded(credential: _saved),
    );
    expect(find.byKey(_biometricButton), findsOneWidget);
    expect(find.text('Ingresar con huella'), findsOneWidget);
    expect(find.text('como Juan Pérez'), findsOneWidget);
    // Botón grande para usar con guantes.
    expect(
      tester.getSize(find.byKey(_biometricButton)).height,
      greaterThanOrEqualTo(56),
    );
    // Sigue habiendo un solo botón principal ("Ingresar").
    expect(findButton<FilledButton>(), findsOneWidget);
  });

  testWidgets('tocar el botón: biometría y login con la credencial guardada', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    final auth = FakeBiometricAuthenticator();
    await _pump(
      tester,
      repo: repo,
      auth: auth,
      storage: await _seeded(credential: _saved),
    );

    await tester.tap(find.byKey(_biometricButton));
    await tester.pumpAndSettle();

    expect(auth.authenticateCalls, 1);
    expect(auth.lastCancel, 'Usar contraseña');
    expect(repo.loginCalls, 1);
    expect(repo.lastEmail, 'juan.perez@dismac.com');
    expect(repo.lastPassword, 'guardada');
  });

  testWidgets('biometría cancelada: no intenta el login ni avisa', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pump(
      tester,
      repo: repo,
      auth: FakeBiometricAuthenticator(result: BiometricResult.cancelled),
      storage: await _seeded(credential: _saved),
    );

    await tester.tap(find.byKey(_biometricButton));
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 0);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('demasiados intentos: pide usar la contraseña', (tester) async {
    final repo = _FakeAuthRepository();
    await _pump(
      tester,
      repo: repo,
      auth: FakeBiometricAuthenticator(result: BiometricResult.lockout),
      storage: await _seeded(credential: _saved),
    );

    await tester.tap(find.byKey(_biometricButton));
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 0);
    expect(
      find.text('Demasiados intentos. Usá tu contraseña.'),
      findsOneWidget,
    );
  });

  testWidgets('contraseña guardada vencida: se borra la credencial y avisa', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(
      error: const ApiException(
        status: 401,
        title: 'No se pudo ingresar',
        detail: 'Usuario o contraseña incorrectos.',
      ),
    );
    final storage = await _seeded(credential: _saved);
    await _pump(
      tester,
      repo: repo,
      auth: FakeBiometricAuthenticator(),
      storage: storage,
    );

    await tester.tap(find.byKey(_biometricButton));
    await tester.pumpAndSettle();

    expect(repo.loginCalls, 1);
    expect(await BiometricCredentialStore(storage).read(), isNull);
    expect(
      find.text(
        'Tu contraseña cambió. Ingresá con tu contraseña y volvé a activar '
        'tu huella.',
      ),
      findsOneWidget,
    );
    expect(find.text('Usuario o contraseña incorrectos.'), findsNothing);
    // Sin credencial, el botón desaparece.
    expect(find.byKey(_biometricButton), findsNothing);
  });

  testWidgets('sin red: mensaje estándar y la credencial se conserva', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(
      error: const ApiException(
        status: 0,
        title: 'Sin conexión',
        isConnectionError: true,
      ),
    );
    final storage = await _seeded(credential: _saved);
    await _pump(
      tester,
      repo: repo,
      auth: FakeBiometricAuthenticator(),
      storage: storage,
    );

    await tester.tap(find.byKey(_biometricButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'No se pudo conectar con el servidor. Revisá tu señal e intentá de '
        'nuevo.',
      ),
      findsOneWidget,
    );
    expect(await BiometricCredentialStore(storage).read(), _saved);
  });

  testWidgets('primera apertura: lanza la biometría sola', (tester) async {
    final repo = _FakeAuthRepository();
    final auth = FakeBiometricAuthenticator();
    await _pump(
      tester,
      repo: repo,
      auth: auth,
      storage: await _seeded(credential: _saved),
      autoPrompt: true,
    );

    expect(auth.authenticateCalls, 1);
    expect(repo.loginCalls, 1);
  });

  testWidgets('tras un cierre de sesión manual no la lanza sola', (
    tester,
  ) async {
    final auth = FakeBiometricAuthenticator();
    await _pump(
      tester,
      repo: _FakeAuthRepository(),
      auth: auth,
      storage: await _seeded(credential: _saved),
    );
    expect(auth.authenticateCalls, 0);
  });

  group('oferta post-login con contraseña', () {
    Future<void> signInWithPassword(WidgetTester tester) async {
      await tester.enterText(
        find.byType(TextField).first,
        'juan.perez@dismac.com',
      );
      await tester.enterText(find.byType(TextField).last, 'secreta');
      await tester.tap(findButtonWithText<FilledButton>('Ingresar'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Sí, activar" guarda la credencial', (tester) async {
      final storage = await _seeded();
      final auth = FakeBiometricAuthenticator();
      late BuildContext context;
      await _pump(
        tester,
        repo: _FakeAuthRepository(),
        auth: auth,
        storage: storage,
        offerContext: () => context,
      );
      context = tester.element(find.byType(LoginScreen));

      await signInWithPassword(tester);
      expect(
        find.text('¿Querés ingresar con huella la próxima vez?'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sí, activar'));
      await tester.pumpAndSettle();

      expect(auth.authenticateCalls, 1);
      final saved = await BiometricCredentialStore(storage).read();
      expect(saved?.email, 'juan.perez@dismac.com');
      expect(saved?.password, 'secreta');
      expect(
        find.text('Listo: la próxima vez ingresá con huella.'),
        findsOneWidget,
      );
    });

    testWidgets('"Ahora no" se recuerda y no se vuelve a ofrecer', (
      tester,
    ) async {
      final storage = await _seeded();
      late BuildContext context;
      await _pump(
        tester,
        repo: _FakeAuthRepository(),
        auth: FakeBiometricAuthenticator(),
        storage: storage,
        offerContext: () => context,
      );
      context = tester.element(find.byType(LoginScreen));

      await signInWithPassword(tester);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      final store = BiometricCredentialStore(storage);
      expect(await store.read(), isNull);
      expect(await store.hasDeclined('juan.perez@dismac.com'), isTrue);

      // Segundo login: ya no pregunta.
      await signInWithPassword(tester);
      expect(
        find.text('¿Querés ingresar con huella la próxima vez?'),
        findsNothing,
      );
    });

    testWidgets('sin biometría en el teléfono no se ofrece', (tester) async {
      late BuildContext context;
      await _pump(
        tester,
        repo: _FakeAuthRepository(),
        auth: FakeBiometricAuthenticator(
          caps: BiometricCapabilities.unsupported,
        ),
        storage: await _seeded(),
        offerContext: () => context,
      );
      context = tester.element(find.byType(LoginScreen));

      await signInWithPassword(tester);
      expect(find.textContaining('próxima vez'), findsNothing);
    });

    testWidgets('otra cuenta guardada: avisa que solo una puede usarla', (
      tester,
    ) async {
      late BuildContext context;
      await _pump(
        tester,
        repo: _FakeAuthRepository(),
        auth: FakeBiometricAuthenticator(),
        storage: await _seeded(
          credential: const BiometricCredential(
            email: 'ana@dismac.com',
            password: 'p',
            name: 'Ana Rojas',
          ),
        ),
        offerContext: () => context,
      );
      context = tester.element(find.byType(LoginScreen));

      await signInWithPassword(tester);
      expect(
        find.text(
          'Solo una cuenta puede usar huella en este teléfono: se '
          'reemplazará la de Ana Rojas.',
        ),
        findsOneWidget,
      );
    });
  });

  testOnScreens('login con botón de biometría no se desborda', (
    tester,
    screen,
  ) async {
    await _pump(
      tester,
      repo: _FakeAuthRepository(),
      auth: FakeBiometricAuthenticator(),
      storage: await _seeded(credential: _saved),
      textScale: true,
    );
    expect(find.byKey(_biometricButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
