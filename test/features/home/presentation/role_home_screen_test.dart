import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/home/presentation/widgets/big_action_tile.dart';
import 'package:logistics_app/features/home/presentation/widgets/greeting_header.dart';

// Inicio por rol (rediseño): panel glanceable con saludo (rol + nombre), la
// acción principal y accesos rápidos, filtrados por rol y por ability. Se
// override la sesión (devSignIn + setAbilities) y las tareas; no toca Drift ni
// canales de plataforma. La barra inferior vive en el shell (no se prueba acá).

/// Tareas de ejemplo: una exige ability, otra no; cada rol tiene la suya.
const _needsAbility = RoleTask(
  id: 'needs-ability',
  label: 'Carga validada',
  icon: Icons.local_shipping,
  route: '/loading',
  roles: {UserRole.driver},
  requiredAbility: 'execution:write',
);
const _noAbility = RoleTask(
  id: 'no-ability',
  label: 'Ruta del día',
  icon: Icons.map,
  route: '/route',
  roles: {UserRole.driver},
);
const _pickerTask = RoleTask(
  id: 'picker-task',
  label: 'Escanear EAN',
  icon: Icons.qr_code,
  route: '/picking',
  roles: {UserRole.picker},
);

ProviderContainer _session(UserRole role, {List<String>? abilities}) {
  final container = ProviderContainer(
    overrides: [
      featureTasksProvider.overrideWithValue(const [
        _needsAbility,
        _noAbility,
        _pickerTask,
      ]),
    ],
  );
  addTearDown(container.dispose);
  final notifier = container.read(sessionProvider.notifier)..devSignIn(role);
  if (abilities != null) notifier.setAbilities(abilities);
  return container;
}

Future<void> _pump(WidgetTester tester, ProviderContainer container) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: RoleHomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra el rol, el nombre y el botón de salir', (tester) async {
    final container = _session(UserRole.driver);
    await _pump(tester, container);

    expect(find.byType(GreetingHeader), findsOneWidget);
    expect(find.text('Chofer'), findsWidgets); // etiqueta del rol en el saludo
    expect(find.text('dev.driver'), findsOneWidget); // nombre del devSignIn
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('con la ability presente muestra la tarjeta con permiso', (
    tester,
  ) async {
    final container = _session(UserRole.driver, abilities: ['execution:write']);
    await _pump(tester, container);

    expect(find.text('Carga validada'), findsOneWidget); // requiere ability
    expect(find.text('Ruta del día'), findsOneWidget);
  });

  testWidgets('sin la ability (abilities cargadas) oculta la tarjeta', (
    tester,
  ) async {
    // Abilities no vacías pero sin el permiso requerido: se aplica el gating.
    final container = _session(UserRole.driver, abilities: ['otro:leer']);
    await _pump(tester, container);

    expect(find.text('Carga validada'), findsNothing); // oculta por permiso
    expect(find.text('Ruta del día'), findsOneWidget); // no pide permiso
  });

  testWidgets('abilities vacías: degradación segura, no oculta nada', (
    tester,
  ) async {
    // devSignIn deja abilities vacías → filtro solo-rol (no oculta por permiso).
    final container = _session(UserRole.driver);
    await _pump(tester, container);

    expect(find.text('Carga validada'), findsOneWidget);
    expect(find.text('Ruta del día'), findsOneWidget);
  });

  testWidgets('filtra por rol: el chofer no ve tareas de otros roles', (
    tester,
  ) async {
    final container = _session(UserRole.driver);
    await _pump(tester, container);

    expect(find.text('Escanear EAN'), findsNothing); // es del preparador
  });

  testWidgets('un rol sin tareas disponibles muestra el estado vacío', (
    tester,
  ) async {
    // El supervisor no tiene ninguna de las tareas de ejemplo.
    final container = _session(UserRole.supervisor);
    await _pump(tester, container);

    expect(
      find.text('No hay flujos disponibles para este rol todavía.'),
      findsOneWidget,
    );
    expect(find.byType(BigActionTile), findsNothing);
  });

  testWidgets('cada uno de los 5 roles ve su etiqueta en el saludo', (
    tester,
  ) async {
    for (final role in UserRole.values) {
      final container = _session(role);
      await _pump(tester, container);
      expect(find.text(role.label), findsWidgets);
    }
  });

  testWidgets('tocar "Cerrar sesión" limpia la sesión', (tester) async {
    final container = _session(UserRole.picker);
    await _pump(tester, container);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider), isNull);
  });
}
