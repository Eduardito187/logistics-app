import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/settlement_status.dart';
import 'package:logistics_app/core/widgets/status_pill.dart';
import 'package:logistics_app/features/carrier/presentation/widgets/settlement_format.dart';

// Formato de montos de liquidación y etiquetas de estado. El separador de
// miles/decimales depende del locale del entorno de test, así que se verifica
// el símbolo de moneda y los dígitos significativos, no la puntuación exacta.

void main() {
  group('formatCents', () {
    test('BOB antepone el símbolo Bs y convierte centavos a unidades', () {
      final text = formatCents(123456, 'BOB');

      expect(text, startsWith('Bs'));
      expect(text, contains('234')); // 1 234 . 56
      expect(text, contains('56'));
    });

    test('USD usa el símbolo de dólar', () {
      expect(formatCents(5000, 'USD'), contains(r'$'));
    });

    test('una moneda sin símbolo propio usa su código como prefijo', () {
      expect(formatCents(1000, 'PEN'), startsWith('PEN'));
    });

    test('un monto de cero sigue siendo válido', () {
      expect(formatCents(0, 'BOB'), contains('0'));
    });
  });

  group('settlementStatusLabel', () {
    test('traduce cada estado de liquidación', () {
      expect(settlementStatusLabel(SettlementStatus.submitted), 'Enviada');
      expect(settlementStatusLabel(SettlementStatus.approved), 'Aprobada');
      expect(settlementStatusLabel(SettlementStatus.paid), 'Pagada');
      expect(settlementStatusLabel(SettlementStatus.disputed), 'En disputa');
      expect(settlementStatusLabel(SettlementStatus.$unknown), 'Desconocido');
    });
  });

  group('settlementStatusTone', () {
    test('asigna el tono semántico', () {
      expect(settlementStatusTone(SettlementStatus.submitted), PillTone.info);
      expect(settlementStatusTone(SettlementStatus.approved), PillTone.warning);
      expect(settlementStatusTone(SettlementStatus.paid), PillTone.success);
      expect(settlementStatusTone(SettlementStatus.disputed), PillTone.danger);
      expect(settlementStatusTone(SettlementStatus.$unknown), PillTone.neutral);
    });
  });
}
