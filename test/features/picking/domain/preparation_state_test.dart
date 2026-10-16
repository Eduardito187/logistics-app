import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/domain/entities/preparation_state.dart';

// Estado local del armado de un pedido. Es progreso de UI puro: no toca red.

void main() {
  group('PreparationState', () {
    test('por defecto está vacío y sin asignación', () {
      const state = PreparationState();

      expect(state.preparedUnitIds, isEmpty);
      expect(state.hasAssignment, isFalse);
      expect(state.isPrepared('u1'), isFalse);
    });

    test('isPrepared reconoce las unidades ya preparadas', () {
      const state = PreparationState(preparedUnitIds: {'u1', 'u2'});

      expect(state.isPrepared('u1'), isTrue);
      expect(state.isPrepared('u3'), isFalse);
    });

    test('hasAssignment es true solo con un vehículo no vacío', () {
      expect(const PreparationState(vehicleId: 'v1').hasAssignment, isTrue);
      expect(const PreparationState(vehicleId: '').hasAssignment, isFalse);
      expect(const PreparationState().hasAssignment, isFalse);
    });

    test('copyWith reemplaza solo los campos indicados', () {
      const base = PreparationState(preparedUnitIds: {'u1'}, lane: 'A1');

      final updated = base.copyWith(vehicleId: 'v9');

      expect(updated.vehicleId, 'v9');
      expect(updated.lane, 'A1'); // conservado
      expect(updated.preparedUnitIds, {'u1'}); // conservado
    });

    test('copyWith agrega una unidad preparada sin perder las previas', () {
      const base = PreparationState(preparedUnitIds: {'u1'});

      final updated = base.copyWith(
        preparedUnitIds: {...base.preparedUnitIds, 'u2'},
      );

      expect(updated.preparedUnitIds, {'u1', 'u2'});
      expect(base.preparedUnitIds, {'u1'}); // el original no muta
    });
  });
}
