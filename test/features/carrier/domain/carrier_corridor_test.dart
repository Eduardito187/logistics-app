import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/corridor_type.dart';
import 'package:logistics_app/features/carrier/domain/models/carrier_corridor.dart';

import '../carrier_fixtures.dart';

// Corredores reales del transportista derivados de sus liquidaciones: pares
// únicos origen→destino con su tipo, sin basura que no se pueda consultar.

void main() {
  test('deduplica el mismo corredor repetido en varias liquidaciones', () {
    final corridors = CarrierCorridor.uniqueFrom([
      settlement(id: 's1'),
      settlement(id: 's2'),
      settlement(id: 's3'),
    ]);

    expect(corridors, hasLength(1));
    expect(corridors.single.from, 'cd-la-paz');
    expect(corridors.single.to, 'cd-santa-cruz');
    expect(corridors.single.type, CorridorType.cdToCd);
  });

  test('el mismo par con tipos distintos son dos corredores', () {
    final corridors = CarrierCorridor.uniqueFrom([
      settlement(
        corridorFrom: 'cd-santa-cruz',
        corridorTo: 'store-scz-centro',
        corridorType: CorridorType.cdToStore,
      ),
      settlement(
        id: 's2',
        corridorFrom: 'cd-santa-cruz',
        corridorTo: 'store-scz-centro',
        corridorType: CorridorType.storePickup,
      ),
    ]);

    expect(corridors, hasLength(2));
    expect(
      corridors.map((c) => c.type),
      containsAll(<CorridorType>[
        CorridorType.cdToStore,
        CorridorType.storePickup,
      ]),
    );
  });

  test('descarta tipos desconocidos y claves vacías (no son consultables)', () {
    final corridors = CarrierCorridor.uniqueFrom([
      settlement(corridorType: CorridorType.$unknown),
      settlement(id: 's2', corridorFrom: '  '),
      settlement(id: 's3', corridorTo: ''),
      settlement(
        id: 's4',
        corridorFrom: 'cd-santa-cruz',
        corridorTo: 'cd-cochabamba',
      ),
    ]);

    expect(corridors, hasLength(1));
    expect(corridors.single.from, 'cd-santa-cruz');
  });

  test('el orden es estable (no baila entre consultas)', () {
    List<String> keysOf(List<CarrierCorridor> list) =>
        list.map((c) => c.key).toList();

    final first = CarrierCorridor.uniqueFrom([
      settlement(corridorFrom: 'cd-santa-cruz', corridorTo: 'cd-la-paz'),
      settlement(id: 's2', corridorFrom: 'cd-cochabamba'),
      settlement(id: 's3'),
    ]);
    final second = CarrierCorridor.uniqueFrom([
      settlement(corridorFrom: 'cd-cochabamba'),
      settlement(id: 's2'),
      settlement(
        id: 's3',
        corridorFrom: 'cd-santa-cruz',
        corridorTo: 'cd-la-paz',
      ),
    ]);

    expect(keysOf(first), keysOf(second));
    expect(keysOf(first), hasLength(3));
  });

  test('sin liquidaciones no hay corredores', () {
    expect(CarrierCorridor.uniqueFrom([]), isEmpty);
  });

  test('dos corredores con el mismo par y tipo son iguales', () {
    const a = CarrierCorridor(
      from: 'cd-la-paz',
      to: 'cd-santa-cruz',
      type: CorridorType.cdToCd,
    );
    const b = CarrierCorridor(
      from: 'cd-la-paz',
      to: 'cd-santa-cruz',
      type: CorridorType.cdToCd,
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
