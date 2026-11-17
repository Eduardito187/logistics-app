import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/plan_status.dart';
import 'package:logistics_app/features/supervisor/presentation/controllers/plans_filter_notifier.dart';

import '../../support/supervisor_fixtures.dart';

// PlansFilterNotifier + filterPlans: estado inicial sin filtro, setear estado y
// texto, limpiar, y el filtrado cliente-side (estado + placa/chofer, sin tildes
// ni mayúsculas, combinados con AND).

void main() {
  group('PlansFilterNotifier', () {
    test('arranca sin estado ni texto', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final filter = container.read(plansFilterProvider);
      expect(filter.status, isNull);
      expect(filter.query, isEmpty);
    });

    test('setStatus y setQuery conservan el otro campo; clear resetea', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(plansFilterProvider.notifier);

      notifier.setStatus(PlanStatus.draft);
      notifier.setQuery('abc');
      expect(container.read(plansFilterProvider).status, PlanStatus.draft);
      expect(container.read(plansFilterProvider).query, 'abc');

      notifier.setStatus(null);
      expect(container.read(plansFilterProvider).status, isNull);
      expect(container.read(plansFilterProvider).query, 'abc');

      notifier.clear();
      expect(container.read(plansFilterProvider).status, isNull);
      expect(container.read(plansFilterProvider).query, isEmpty);
    });
  });

  group('filterPlans', () {
    final plans = [
      plan(
        id: 'p1',
        status: PlanStatus.published,
        plate: '1234ABC',
        driverName: 'Juan Pérez',
      ),
      plan(
        id: 'p2',
        status: PlanStatus.draft,
        plate: '5678XYZ',
        driverName: 'María López',
      ),
    ];

    test('sin filtro devuelve todos en el mismo orden', () {
      final result = filterPlans(plans, (status: null, query: ''));
      expect(result.map((p) => p.id), ['p1', 'p2']);
    });

    test('filtra por estado', () {
      final result = filterPlans(plans, (
        status: PlanStatus.draft,
        query: '',
      ));
      expect(result.map((p) => p.id), ['p2']);
    });

    test('busca por placa', () {
      final result = filterPlans(plans, (status: null, query: '5678'));
      expect(result.map((p) => p.id), ['p2']);
    });

    test('busca por chofer sin distinguir tildes ni mayúsculas', () {
      final result = filterPlans(plans, (status: null, query: 'perez'));
      expect(result.map((p) => p.id), ['p1']);
    });

    test('combina estado y texto con AND', () {
      // Estado draft + "perez" (de otro plan) no coincide con nadie.
      final result = filterPlans(plans, (
        status: PlanStatus.draft,
        query: 'perez',
      ));
      expect(result, isEmpty);
    });
  });

  test('normalizePlanQuery saca tildes, ñ y pasa a minúsculas', () {
    expect(normalizePlanQuery('  Múñoz '), 'munoz');
    expect(normalizePlanQuery('GARCÍA'), 'garcia');
  });
}
