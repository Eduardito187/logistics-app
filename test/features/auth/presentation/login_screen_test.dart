import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:logistics_app/features/auth/domain/usecases/sign_in.dart';
import 'package:logistics_app/features/auth/presentation/login_screen.dart';
import 'package:logistics_app/features/auth/presentation/widgets/auth_header.dart';
import '../../../support/button_finders.dart';

// Pantalla de login: encabezado de marca, dos campos y un único botón
// "Ingresar". No tiene selección de rol ni botones de dev (el rol lo da el
// backend). Se override signInProvider con un repositorio falso para no tocar
// red ni sesión real.

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.error, this.gate});

  final Object? error;
  final Completer<void>? gate;
  bool loginCalled = false;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> login({required String email, required String password}) async {
    loginCalled = true;
    lastEmail = email;
    lastPassword = password;
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }
}

Future<void> _pump(WidgetTester tester, _FakeAuthRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [signInProvider.overrideWithValue(SignIn(repo))],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el encabezado de marca, los campos y el botón', (
    tester,
  ) async {
    await _pump(tester, _FakeAuthRepository());

    expect(find.byType(AuthHeader), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('DisTrack')), findsWidgets);
    expect(find.text('Ingresá a tu cuenta'), findsOneWidget);
    expect(find.text('Usuario o correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(findButtonWithText<FilledButton>('Ingresar'), findsOneWidget);
    // Dos campos: usuario y contraseña.
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('NO hay selección de rol ni botones de desarrollo', (
    tester,
  ) async {
    await _pump(tester, _FakeAuthRepository());

    // Ningún rol se ofrece como opción en el login (el rol sale del backend).
    expect(find.text('Chofer'), findsNothing);
    expect(find.text('Preparador / andén'), findsNothing);
    expect(find.text('Tienda'), findsNothing);
    expect(find.text('Transportista externo'), findsNothing);
    expect(find.text('Supervisor'), findsNothing);
    expect(find.textContaining('Entrar como'), findsNothing);
    // Sin desplegables ni selección de rol.
    expect(find.byType(DropdownButton<Object?>), findsNothing);
    expect(find.byType(SegmentedButton<Object?>), findsNothing);
    // Un solo botón de acción.
    expect(findButton<FilledButton>(), findsOneWidget);
  });

  testWidgets('campos vacíos: muestra aviso y NO intenta ingresar', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Ingresá tu usuario y contraseña.'), findsOneWidget);
    expect(repo.loginCalled, isFalse);
  });

  testWidgets('credenciales ok: envía el usuario recortado, sin error', (
    tester,
  ) async {
    final repo = _FakeAuthRepository();
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField).first, '  user@x.com  ');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(repo.loginCalled, isTrue);
    expect(repo.lastEmail, 'user@x.com'); // recortado
    expect(repo.lastPassword, 'secret');
    // Sin aviso de error en pantalla.
    expect(find.text('Usuario o contraseña incorrectos.'), findsNothing);
  });

  testWidgets('credenciales inválidas: muestra el error sin salir del login', (
    tester,
  ) async {
    final repo = _FakeAuthRepository(
      error: const ApiException(
        status: 401,
        title: 'No se pudo ingresar',
        detail: 'Usuario o contraseña incorrectos.',
      ),
    );
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField).first, 'user@x.com');
    await tester.enterText(find.byType(TextField).last, 'mala');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    // El error viaja por el listener a un SnackBar (showErrorSnack usa .message).
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    // Sigue en el login (no se deslogueó ni navegó).
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('mientras carga: muestra spinner y deshabilita el botón', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = _FakeAuthRepository(gate: gate);
    await _pump(tester, repo);

    await tester.enterText(find.byType(TextField).first, 'user@x.com');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.tap(find.text('Ingresar'));
    await tester.pump(); // dispara submit → AsyncLoading

    // El botón muestra el spinner y queda deshabilitado.
    expect(
      find.descendant(
        of: findButton<FilledButton>(),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(findButton<FilledButton>());
    expect(button.onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    // Terminó la carga: vuelve el texto "Ingresar".
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('el ojo alterna la contraseña entre puntos y texto', (
    tester,
  ) async {
    await _pump(tester, _FakeAuthRepository());

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).last);

    expect(passwordField().obscureText, isTrue);
    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar contraseña'));
    await tester.pump();
    expect(passwordField().obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('sin conexión: no promete reintento automático y ofrece '
      '"Reintentar"', (tester) async {
    final repo = _FakeAuthRepository(
      error: const ApiException(
        status: 0,
        title: 'Sin conexión',
        isConnectionError: true,
      ),
    );
    await _pump(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'chofer@dismac.bo');
    await tester.enterText(find.byType(TextField).last, 'secreta');

    await tester.tap(findButtonWithText<FilledButton>('Ingresar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'No se pudo conectar con el servidor. Revisá tu señal e intentá de '
        'nuevo.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('se reintentará'), findsNothing);

    // "Reintentar" vuelve a enviar el login con los mismos datos.
    repo.loginCalled = false;
    // Espera a que el aviso termine de entrar (si no, el toque cae debajo).
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    expect(repo.loginCalled, isTrue);
    expect(repo.lastEmail, 'chofer@dismac.bo');
  });
}
