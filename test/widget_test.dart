import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/app.dart';
import 'package:logistics_app/core/auth/user_role.dart';

void main() {
  testWidgets('sin sesión muestra el login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LogisticsApp()));
    await tester.pumpAndSettle();

    expect(find.text('Dismac Logística'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('cada rol entra a su propia pantalla de inicio y puede salir', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LogisticsApp()));
    await tester.pumpAndSettle();

    for (final role in UserRole.values) {
      final button = find.byKey(ValueKey('dev-login-${role.name}'));
      // Los TextField traen su propio Scrollable: se indica el de la lista del login.
      await tester.scrollUntilVisible(
        button,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, role.label), findsOneWidget);
      expect(find.text(role.tasks.first), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresar'), findsOneWidget);
    }
  });
}
