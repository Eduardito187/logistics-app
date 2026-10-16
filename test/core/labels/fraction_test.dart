import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/labels/fraction.dart';
import 'package:logistics_app/core/labels/label_format_exception.dart';

// Casos límite y de igualdad de [Fraction] que complementan a
// label_payload_test.dart (que ya cubre el toCanonical básico y los rangos
// gruesos). Aquí se fijan los bordes exactos de validación y el contrato de
// igualdad/hashCode.

void main() {
  group('Fraction — construcción válida en los bordes', () {
    test('acepta index == total (la última unidad/pieza)', () {
      expect(Fraction(2, 2).toCanonical(), '2/2');
      expect(Fraction(999, 999).toCanonical(), '999/999');
    });

    test('acepta total == 1 con index == 1', () {
      expect(Fraction(1, 1).toCanonical(), '1/1');
    });

    test('acepta el total máximo 999', () {
      expect(Fraction(1, 999).toCanonical(), '1/999');
      expect(Fraction(500, 999).index, 500);
    });
  });

  group('Fraction — rechazo en los bordes exactos', () {
    test('total == 0 es inválido (primer valor fuera de 1..999)', () {
      expect(() => Fraction(1, 0), throwsA(isA<LabelFormatException>()));
    });

    test('total negativo es inválido', () {
      expect(() => Fraction(1, -5), throwsA(isA<LabelFormatException>()));
    });

    test('total == 1000 es inválido (primero fuera por arriba)', () {
      expect(() => Fraction(1, 1000), throwsA(isA<LabelFormatException>()));
    });

    test('index == 0 es inválido aunque el total sea válido', () {
      expect(() => Fraction(0, 5), throwsA(isA<LabelFormatException>()));
    });

    test('index negativo es inválido', () {
      expect(() => Fraction(-1, 5), throwsA(isA<LabelFormatException>()));
    });

    test('index == total + 1 es inválido', () {
      expect(() => Fraction(6, 5), throwsA(isA<LabelFormatException>()));
    });

    test('el mensaje del error de total nombra el rango 1..999', () {
      expect(
        () => Fraction(1, 0),
        throwsA(
          isA<LabelFormatException>().having(
            (e) => e.reason,
            'reason',
            contains('1..999'),
          ),
        ),
      );
    });

    test('el mensaje del error de índice nombra el rango permitido', () {
      expect(
        () => Fraction(9, 5),
        throwsA(
          isA<LabelFormatException>().having(
            (e) => e.reason,
            'reason',
            allOf(contains('9'), contains('1..5')),
          ),
        ),
      );
    });
  });

  group('Fraction — igualdad y hashCode', () {
    test('dos fracciones con mismo índice y total son iguales', () {
      expect(Fraction(2, 3), equals(Fraction(2, 3)));
      expect(Fraction(2, 3).hashCode, Fraction(2, 3).hashCode);
    });

    test('difieren si cambia el índice', () {
      expect(Fraction(1, 3) == Fraction(2, 3), isFalse);
    });

    test('difieren si cambia el total', () {
      expect(Fraction(1, 2) == Fraction(1, 3), isFalse);
    });

    test('no es igual a un objeto de otro tipo', () {
      expect(Fraction(1, 2) == Object(), isFalse);
      // ignore: unrelated_type_equality_checks
      expect(Fraction(1, 2) == '1/2', isFalse);
    });
  });
}
