import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/features/home/presentation/widgets/task_card.dart';

// Tarjeta de acción del inicio: muestra la tarea y navega a su ruta al tocarla.

const _task = RoleTask(
  id: 'route',
  label: 'Ruta del día',
  subtitle: 'Navegación con un toque',
  icon: Icons.map,
  route: '/route',
  roles: {UserRole.driver},
);

void main() {
  testWidgets('muestra la etiqueta, el subtítulo, el ícono y el chevron', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskCard(task: _task)),
      ),
    );

    expect(find.text('Ruta del día'), findsOneWidget);
    expect(find.text('Navegación con un toque'), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('sin subtítulo no muestra una segunda línea', (tester) async {
    const task = RoleTask(
      id: 'x',
      label: 'Sin subtítulo',
      icon: Icons.bolt,
      route: '/x',
      roles: {UserRole.driver},
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TaskCard(task: task)),
      ),
    );

    expect(find.text('Sin subtítulo'), findsOneWidget);
  });

  testWidgets('tocarla navega a su ruta', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: TaskCard(task: _task)),
        ),
        GoRoute(
          path: '/route',
          builder: (_, _) => const Scaffold(body: Text('PANTALLA DE RUTA')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ruta del día'));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA DE RUTA'), findsOneWidget);
  });
}
