import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/app_nav.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/core/widgets/floating_pill_nav_bar.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/home/presentation/widgets/greeting_header.dart';

import '../../support/no_home_prefetch.dart';

// Regresiones del shell inferior (5 pestañas, la central incluida). El bug que
// teníamos: la barra se estiraba a TODA la pantalla (un `Center` expandía en
// vertical) y el cuerpo quedaba en 0 → todo negro. Se fija con
// `Align(heightFactor:1)`. Las pestañas cambian el contenido en la MISMA
// pantalla (IndexedStack), incluida la central.

const _driverTask = RoleTask(
  id: 'delivery',
  label: 'Entrega en curso',
  icon: Icons.local_shipping,
  route: '/driver/delivery',
  roles: {UserRole.driver},
  accent: true,
);

/// Shell mínimo con la barra real pero pestañas placeholder (sin pantallas de
/// red): reproduce la estructura del HomeShell para los tests de layout.
Widget _shell({required int index, ValueChanged<int>? onTap}) {
  return Scaffold(
    extendBody: true,
    body: IndexedStack(
      sizing: StackFit.expand,
      index: index,
      children: const [
        RoleHomeScreen(),
        Center(child: Text('TAREAS')),
        Center(child: Text('CENTRO')),
        Center(child: Text('AVISOS')),
        Center(child: Text('PERFIL')),
      ],
    ),
    bottomNavigationBar: FloatingPillNavBar(
      sideTabs: kPrimaryNavTabs,
      currentIndex: index,
      onTap: onTap ?? (_) {},
      centerLabel: 'Entrega',
      centerIcon: Icons.local_shipping,
    ),
  );
}

ProviderContainer _container() {
  final container = ProviderContainer(
    overrides: [
      noHomePrefetchOverride,
      featureTasksProvider.overrideWithValue(const [_driverTask]),
    ],
  );
  addTearDown(container.dispose);
  container.read(sessionProvider.notifier).devSignIn(UserRole.driver);
  return container;
}

void main() {
  testWidgets('la barra flotante NO se estira a toda la pantalla', (
    tester,
  ) async {
    final container = _container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: _shell(index: 0)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    final navHeight = tester.getSize(find.byType(FloatingPillNavBar)).height;
    expect(navHeight, lessThan(160));
  });

  testWidgets('el Inicio muestra su contenido ONSTAGE (no negro)', (
    tester,
  ) async {
    final container = _container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: _shell(index: 0)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RoleHomeScreen), findsOneWidget);
    expect(find.byType(GreetingHeader), findsOneWidget);
    expect(find.textContaining('Hola'), findsOneWidget);
    expect(find.text('Entrega en curso'), findsWidgets);
  });

  testWidgets('tocar una pestaña lateral cambia el contenido en la pantalla', (
    tester,
  ) async {
    var index = 0;
    final container = _container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => _shell(
              index: index,
              onTap: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(GreetingHeader), findsOneWidget);
    expect(find.text('AVISOS'), findsNothing);

    // Avisos es la pestaña lateral en índice 3.
    await tester.tap(find.text('Avisos'));
    await tester.pump();
    expect(index, 3);
    expect(find.text('AVISOS'), findsOneWidget);
    expect(find.byType(GreetingHeader), findsNothing);
  });

  testWidgets('la pestaña CENTRAL cambia el contenido (no es un link)', (
    tester,
  ) async {
    var index = 0;
    final container = _container();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => _shell(
              index: index,
              onTap: (i) => setState(() => index = i),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    // Tocar el botón central (ícono camión DENTRO de la barra) → índice 2.
    await tester.tap(
      find.descendant(
        of: find.byType(FloatingPillNavBar),
        matching: find.byIcon(Icons.local_shipping),
      ),
    );
    await tester.pump();
    expect(index, 2);
    expect(find.text('CENTRO'), findsOneWidget);
  });

  test('homeTabProvider cambia de índice', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(homeTabProvider), 0);
    container.read(homeTabProvider.notifier).set(2);
    expect(container.read(homeTabProvider), 2);
  });

  test('la acción central (FAB) cambia según el rol', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final tasks = container.read(featureTasksProvider);

    final driver = centerActionFor(UserRole.driver, tasks);
    final store = centerActionFor(UserRole.store, tasks);
    final supervisor = centerActionFor(UserRole.supervisor, tasks);

    expect(driver, isNotNull);
    expect(store, isNotNull);
    expect(supervisor, isNotNull);
    expect(driver!.route, isNot(store!.route));
    expect(driver.route, isNot(supervisor!.route));
    expect(driver.visibleFor(UserRole.driver), isTrue);
    expect(driver.visibleFor(UserRole.store), isFalse);
  });
}
