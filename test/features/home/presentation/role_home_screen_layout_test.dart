import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/home/presentation/all_tasks_screen.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/home/presentation/widgets/big_action_tile.dart';
import 'package:logistics_app/features/home/presentation/widgets/greeting_header.dart';

import '../../../support/no_home_prefetch.dart';
import '../../../support/screen_sizes.dart';

// Layout del inicio (panel) y de Tareas (grilla) en teléfono chico, teléfono y
// tablets (vertical y horizontal), con letra normal y 1.3x. Usan las tareas
// reales de cada rol y el tema real de la app. Un desborde hace fallar el test
// solo (la barra inferior vive en el shell y no se prueba acá).

Future<void> _pump(
  WidgetTester tester,
  Widget screen,
  UserRole role, {
  double textScale = 1.0,
}) async {
  final container = ProviderContainer(overrides: [noHomePrefetchOverride]);
  addTearDown(container.dispose);
  container.read(sessionProvider.notifier).devSignIn(role);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, child) => withTextScale(child!, scale: textScale),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Columnas reales: cuántos tiles comparten la fila del primero.
int _columnsOnFirstRow(WidgetTester tester) {
  final cards = find.byType(BigActionTile);
  final firstTop = tester.getTopLeft(cards.first).dy;
  return tester
      .widgetList(cards)
      .where((w) => tester.getTopLeft(find.byWidget(w)).dy == firstTop)
      .length;
}

void main() {
  const roles = [
    UserRole.driver,
    UserRole.picker,
    UserRole.store,
    UserRole.carrier,
    UserRole.supervisor,
  ];

  for (final role in roles) {
    testOnScreens('inicio de ${role.name} no se desborda (letra 1.3x)', (
      tester,
      screen,
    ) async {
      await _pump(tester, const RoleHomeScreen(), role, textScale: 1.3);

      // El saludo siempre está; cada rol tiene al menos su acción principal.
      expect(find.byType(GreetingHeader), findsOneWidget);
      expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    });

    testOnScreens('tareas de ${role.name} no se desbordan (letra 1.3x)', (
      tester,
      screen,
    ) async {
      await _pump(tester, const AllTasksScreen(), role, textScale: 1.3);
      expect(find.byType(BigActionTile), findsWidgets);
    });
  }

  testOnScreens('columnas de la grilla de Tareas según el tamaño', (
    tester,
    screen,
  ) async {
    // El supervisor tiene varias tareas: alcanza para llenar 3 columnas.
    await _pump(tester, const AllTasksScreen(), UserRole.supervisor);

    final expected = switch (screen) {
      TestScreen.smallPhone || TestScreen.phone => 1,
      TestScreen.tabletPortrait => 2,
      TestScreen.tabletLandscape => 3,
    };
    final available = find.byType(BigActionTile).evaluate().length;
    expect(
      _columnsOnFirstRow(tester),
      expected < available ? expected : available,
    );
  });

  testOnScreens(
    'en tablet la grilla de Tareas no se estira de borde a borde',
    (tester, screen) async {
      await _pump(tester, const AllTasksScreen(), UserRole.supervisor);

      final firstCard = tester.getRect(find.byType(BigActionTile).first);
      // Margen mínimo a la izquierda; en tablet ancha el contenido queda
      // centrado (margen izquierdo mayor al mínimo de teléfono).
      expect(firstCard.left, greaterThanOrEqualTo(16));
      if (screen == TestScreen.tabletLandscape) {
        expect(firstCard.left, greaterThan(16));
      }
    },
    screens: const [TestScreen.tabletPortrait, TestScreen.tabletLandscape],
  );
}
