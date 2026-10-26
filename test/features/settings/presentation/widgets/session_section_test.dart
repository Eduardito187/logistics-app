import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/network/api_exception.dart';
import 'package:logistics_app/features/settings/presentation/widgets/session_section.dart';
import '../../../../support/button_finders.dart';

// Sección de sesión: renovar token (/app/auth/refresh) y cerrar sesión. Se
// override sessionProvider con un notifier falso para no tocar la red ni el
// almacén.

class _FakeSession extends SessionNotifier {
  _FakeSession({this.initial, this.refreshError});
  final Session? initial;
  final ApiException? refreshError;
  bool refreshed = false;
  bool signedOut = false;

  @override
  Session? build() => initial;

  @override
  Future<void> refreshToken() async {
    refreshed = true;
    if (refreshError != null) throw refreshError!;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
    state = null;
  }
}

Session _session({String? token}) =>
    Session(userName: 'Juan Pérez', role: UserRole.driver, token: token);

Future<void> _pump(
  WidgetTester tester, {
  required Session session,
  required _FakeSession fake,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sessionProvider.overrideWith(() => fake)],
      child: MaterialApp(
        home: Scaffold(body: SessionSection(session: session)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el nombre y el rol de la sesión', (tester) async {
    await _pump(
      tester,
      session: _session(token: 't'),
      fake: _FakeSession(),
    );

    expect(find.text('Juan Pérez'), findsOneWidget);
    expect(find.text('Chofer'), findsOneWidget);
  });

  testWidgets('sin token el botón de renovar está deshabilitado', (
    tester,
  ) async {
    await _pump(tester, session: _session(), fake: _FakeSession());

    final button = tester.widget<OutlinedButton>(
      findButtonWithText<OutlinedButton>('Renovar sesión'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('renovar con éxito muestra "Sesión renovada."', (tester) async {
    final fake = _FakeSession(initial: _session(token: 't'));
    await _pump(
      tester,
      session: _session(token: 't'),
      fake: fake,
    );

    await tester.tap(find.text('Renovar sesión'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(fake.refreshed, isTrue);
    expect(find.text('Sesión renovada.'), findsOneWidget);
  });

  testWidgets('renovar con error muestra el mensaje del error', (tester) async {
    final fake = _FakeSession(
      initial: _session(token: 't'),
      refreshError: const ApiException(
        status: 401,
        title: 'No se pudo',
        detail: 'No se pudo renovar la sesión.',
      ),
    );
    await _pump(
      tester,
      session: _session(token: 't'),
      fake: fake,
    );

    await tester.tap(find.text('Renovar sesión'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('No se pudo renovar la sesión.'), findsOneWidget);
  });

  testWidgets('cerrar sesión llama a signOut', (tester) async {
    final fake = _FakeSession(initial: _session(token: 't'));
    await _pump(
      tester,
      session: _session(token: 't'),
      fake: fake,
    );

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pump();

    expect(fake.signedOut, isTrue);
  });
}
