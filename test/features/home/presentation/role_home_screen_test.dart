import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/core/navigation/feature_tasks.dart';
import 'package:logistics_app/core/navigation/role_task.dart';
import 'package:logistics_app/core/offline/app_database.dart';
import 'package:logistics_app/core/offline/connectivity_notifier.dart';
import 'package:logistics_app/core/offline/sync_queue_provider.dart';
import 'package:logistics_app/features/home/presentation/home_prefetch.dart';
import 'package:logistics_app/features/home/presentation/role_home_screen.dart';
import 'package:logistics_app/features/home/presentation/widgets/profile_header.dart';
import 'package:logistics_app/features/home/presentation/widgets/task_card.dart';

// Inicio por rol: muestra el perfil del usuario y filtra las tarjetas por rol y
// por ability. Se override la sesión (devSignIn + setAbilities), el stream de
// cola y la conectividad (que usa el SyncBadge de la AppBar) para no tocar
// Drift ni el canal de plataforma.

/// Conectividad falsa: siempre en línea, sin suscribirse al canal real.
class _FakeConnectivity extends ConnectivityNotifier {
  @override
  Future<bool> build() async => true;
}

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

/// Precarga falsa: registra con qué rol se llamó y no toca la red.
class _RecordingPrefetch extends HomePrefetcher {
  final List<UserRole> calls = [];

  @override
  void call(WidgetRef ref, UserRole role) => calls.add(role);
}

ProviderContainer _session(
  UserRole role, {
  List<String>? abilities,
  _RecordingPrefetch? prefetch,
}) {
  final container = ProviderContainer(
    overrides: [
      homePrefetcherProvider.overrideWithValue(
        prefetch ?? _RecordingPrefetch(),
      ),
      featureTasksProvider.overrideWithValue(const [
        _needsAbility,
        _noAbility,
        _pickerTask,
      ]),
      syncQueueProvider.overrideWith(
        (ref) => Stream<List<OutboxAction>>.value(const []),
      ),
      connectivityProvider.overrideWith(_FakeConnectivity.new),
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
  testWidgets('muestra la etiqueta del rol, el perfil y el botón de salir', (
    tester,
  ) async {
    final container = _session(UserRole.driver);
    await _pump(tester, container);

    // La etiqueta del rol aparece una sola vez, en el perfil: el título grande
    // del FlexibleSpaceBar se quitó (se veía tosco al expandir).
    expect(find.text('Chofer'), findsOneWidget);
    expect(
      tester.widget<FlexibleSpaceBar>(find.byType(FlexibleSpaceBar)).title,
      isNull,
    );
    expect(find.text('dev.driver'), findsOneWidget); // nombre del devSignIn
    expect(find.byType(ProfileHeader), findsOneWidget);
    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    // Header: campana de notificaciones; la sincronización va por debajo.
    expect(find.byTooltip('Notificaciones'), findsOneWidget);
    expect(find.byTooltip('Sincronización'), findsNothing);
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
    expect(find.byType(TaskCard), findsNothing);
  });

  testWidgets('cada uno de los 5 roles ve su etiqueta', (tester) async {
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

  testWidgets('al entrar precarga una sola vez con el rol de la sesión', (
    tester,
  ) async {
    final prefetch = _RecordingPrefetch();
    final container = _session(UserRole.store, prefetch: prefetch);
    await _pump(tester, container);
    // Rebuilds del inicio (scroll, cambios de sesión) no repiten la precarga.
    await tester.pump();

    expect(prefetch.calls, [UserRole.store]);
    // Sin spinner nuevo: el inicio se pinta igual que siempre.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
