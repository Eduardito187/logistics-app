import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/core/auth/session.dart';
import 'package:logistics_app/core/auth/user_role.dart';
import 'package:logistics_app/features/carrier/data/repositories/carrier_repository_impl.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_routes.dart';
import 'package:logistics_app/features/carrier/presentation/carrier_tariff_screen.dart';
import 'package:logistics_app/features/carrier/presentation/controllers/carrier_controllers.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/assignment_form.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/carrier_office_only.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/cheapest_tariff_form.dart';

import '../carrier_fixtures.dart';
import '../carrier_test_harness.dart';

// Herramientas de compra/costeo de OFICINA (asignación por volumen y tarifa más
// barata entre TODOS los transportistas): el transportista externo no las ve ni
// como acción ni como pantalla; la oficina sigue igual. El backend ya le
// responde 403 en esos dos endpoints.

Session _session(UserRole role, List<String> abilities) =>
    Session(userName: 'u', role: role, abilities: abilities);

/// Abre [location] con las rutas reales del transportista.
Future<void> _pumpRoute(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  final router = GoRouter(initialLocation: location, routes: carrierRoutes);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('permiso', () {
    test('transportista: no puede (aunque tenga carriers:write)', () {
      expect(
        canUseCarrierOfficeTools(
          _session(UserRole.carrier, const ['carriers:write', 'tracking:read']),
        ),
        isFalse,
      );
    });

    test('oficina (planning:write) y admin (comodín): sí pueden', () {
      expect(
        canUseCarrierOfficeTools(
          _session(UserRole.supervisor, const ['planning:write']),
        ),
        isTrue,
      );
      expect(
        canUseCarrierOfficeTools(_session(UserRole.supervisor, const ['*'])),
        isTrue,
      );
    });

    test('sin sesión o sin abilities conocidas: no (fail-closed)', () {
      expect(canUseCarrierOfficeTools(null), isFalse);
      // dev-login o `/me` caído: son datos de otros transportistas, no se
      // degrada a "mostrar".
      expect(
        canUseCarrierOfficeTools(_session(UserRole.carrier, const [])),
        isFalse,
      );
    });
  });

  group('pantallas', () {
    testWidgets('transportista: la asignación por volumen no se abre', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(FakeCarrierRepository()),
          carrierSessionOverride(),
        ],
      );

      await _pumpRoute(tester, container, '/carrier/assignment');

      expect(find.text('Solo para la oficina'), findsOneWidget);
      expect(find.byType(AssignmentForm), findsNothing);

      container.dispose();
    });

    testWidgets('transportista: la tarifa más barata no se abre', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(FakeCarrierRepository()),
          carrierSessionOverride(),
        ],
      );

      await _pumpRoute(tester, container, '/carrier/tariff/cheapest');

      expect(find.text('Solo para la oficina'), findsOneWidget);
      expect(find.byType(CheapestTariffForm), findsNothing);

      container.dispose();
    });

    testWidgets('oficina: las dos herramientas se abren igual que antes', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(FakeCarrierRepository()),
          officeSessionOverride(),
        ],
      );

      await _pumpRoute(tester, container, '/carrier/assignment');
      expect(find.byType(AssignmentForm), findsOneWidget);
      expect(find.text('Solo para la oficina'), findsNothing);

      await _pumpRoute(tester, container, '/carrier/tariff/cheapest');
      expect(find.byType(CheapestTariffForm), findsOneWidget);
      expect(find.text('Solo para la oficina'), findsNothing);

      container.dispose();
    });
  });

  group('atajos de la pantalla de tarifas', () {
    Future<ProviderContainer> pumpTariff(
      WidgetTester tester,
      Override session,
    ) async {
      final container = ProviderContainer(
        overrides: [
          carrierRepositoryProvider.overrideWithValue(FakeCarrierRepository()),
          session,
        ],
      );
      container.read(selectedCarrierProvider.notifier).select(carrier());
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CarrierTariffScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('transportista: no ve los atajos de compra/costeo', (
      tester,
    ) async {
      final container = await pumpTariff(tester, carrierSessionOverride());

      expect(find.byTooltip('Asignación por volumen'), findsNothing);
      expect(find.byTooltip('Tarifa más barata'), findsNothing);
      // Su propia consulta de tarifas sigue disponible.
      expect(find.text('Tarifas por corredor'), findsOneWidget);

      // Se descarta ACÁ (los providers de pantalla usan `cacheFor`, que arma un
      // Timer de 60 s al quedarse sin oyentes).
      container.dispose();
    });

    testWidgets('oficina: sí ve los atajos', (tester) async {
      final container = await pumpTariff(tester, officeSessionOverride());

      expect(find.byTooltip('Asignación por volumen'), findsOneWidget);
      expect(find.byTooltip('Tarifa más barata'), findsOneWidget);

      container.dispose();
    });
  });
}
