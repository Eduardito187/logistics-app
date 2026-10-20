import 'package:intl/intl.dart';

import '../../../../core/api/models/settlement_status.dart';
import '../../../../core/widgets/status_pill.dart';

/// Formatea un monto en centavos con su moneda (p. ej. 123456 BOB → "Bs 1.234,56").
String formatCents(int amountCents, String currency) {
  // Un NumberFormat por moneda, reutilizado: crearlo en cada fila de una lista
  // larga es caro (parsea patrones del locale).
  final format = _formats.putIfAbsent(
    currency,
    () => NumberFormat.currency(name: currency, symbol: _symbolFor(currency)),
  );
  return format.format(amountCents / 100);
}

final Map<String, NumberFormat> _formats = {};

String _symbolFor(String currency) => switch (currency.toUpperCase()) {
  'BOB' => 'Bs ',
  'USD' => r'$',
  _ => '$currency ',
};

/// Etiqueta en español para el estado de una liquidación.
String settlementStatusLabel(SettlementStatus status) => switch (status) {
  SettlementStatus.submitted => 'Enviada',
  SettlementStatus.approved => 'Aprobada',
  SettlementStatus.paid => 'Pagada',
  SettlementStatus.disputed => 'En disputa',
  SettlementStatus.$unknown => 'Desconocido',
};

/// Tono de la pastilla según el estado.
PillTone settlementStatusTone(SettlementStatus status) => switch (status) {
  SettlementStatus.submitted => PillTone.info,
  SettlementStatus.approved => PillTone.warning,
  SettlementStatus.paid => PillTone.success,
  SettlementStatus.disputed => PillTone.danger,
  SettlementStatus.$unknown => PillTone.neutral,
};
