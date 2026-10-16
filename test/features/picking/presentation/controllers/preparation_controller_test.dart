import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/picking/presentation/controllers/preparation_controller.dart';

// Controller de progreso de armado (Notifier family por pedido). Estado de UI
// puro: no toca red. Se maneja vía ProviderContainer.

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  PreparationController ctrl(String order) =>
      container.read(preparationControllerProvider(order).notifier);

  test('estado inicial vacío, sin asignación', () {
    final state = container.read(preparationControllerProvider('A'));

    expect(state.preparedUnitIds, isEmpty);
    expect(state.hasAssignment, isFalse);
    expect(state.lane, isNull);
  });

  test('assign fija vehículo y carril', () {
    ctrl('A').assign(vehicleId: 'V1', lane: 'Carril 3');

    final state = container.read(preparationControllerProvider('A'));
    expect(state.vehicleId, 'V1');
    expect(state.lane, 'Carril 3');
    expect(state.hasAssignment, isTrue);
  });

  test('markPrepared agrega la unidad y es idempotente', () {
    ctrl('A')
      ..markPrepared('u1')
      ..markPrepared('u1')
      ..markPrepared('u2');

    final state = container.read(preparationControllerProvider('A'));
    expect(state.preparedUnitIds, {'u1', 'u2'});
    expect(state.isPrepared('u1'), isTrue);
    expect(state.isPrepared('u3'), isFalse);
  });

  test('cada pedido (family) tiene su propio estado aislado', () {
    ctrl('A').markPrepared('u1');
    ctrl('B').assign(vehicleId: 'V-B');

    expect(container.read(preparationControllerProvider('A')).preparedUnitIds, {
      'u1',
    });
    expect(
      container.read(preparationControllerProvider('A')).hasAssignment,
      isFalse,
    );
    expect(
      container.read(preparationControllerProvider('B')).preparedUnitIds,
      isEmpty,
    );
    expect(container.read(preparationControllerProvider('B')).vehicleId, 'V-B');
  });

  test('assign conserva las unidades ya preparadas', () {
    ctrl('A').markPrepared('u1');
    ctrl('A').assign(vehicleId: 'V1', lane: 'A1');

    final state = container.read(preparationControllerProvider('A'));
    expect(state.preparedUnitIds, {'u1'});
    expect(state.lane, 'A1');
  });
}
