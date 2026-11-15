import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/dispatch_authorization_reason_code.dart';
import 'package:logistics_app/features/picking/presentation/widgets/dispatch_lines_body.dart';

import '../../picking_test_harness.dart';

// Un producto sin autorizar por falta de camión NO es un error del preparador:
// se destraba asignándole un camión. Se decide por el CÓDIGO del backend.

void main() {
  test('sin camión asignado: pendiente, con qué hacer', () {
    final line = buildDispatchLine(
      authorized: false,
      authorizedReason: 'sin plan publicado',
      authorizedReasonCode: DispatchAuthorizationReasonCode.notAssigned,
    );

    expect(needsVehicle(line), isTrue);
    expect(
      dispatchBlockText(line),
      'Asigná un camión al pedido para poder etiquetarlo.',
    );
  });

  test('camión no apto: es un bloqueo, no una espera', () {
    final line = buildDispatchLine(
      authorized: false,
      authorizedReasonCode: DispatchAuthorizationReasonCode.vehicleUnfit,
    );

    expect(needsVehicle(line), isFalse);
    expect(dispatchBlockText(line), contains('no está apto'));
  });

  test('sin código se muestra el motivo del backend', () {
    final line = buildDispatchLine(
      authorized: false,
      authorizedReason: 'producto bloqueado por calidad',
    );

    expect(needsVehicle(line), isFalse);
    expect(dispatchBlockText(line), 'producto bloqueado por calidad');
  });

  test('un producto autorizado nunca está pendiente', () {
    expect(
      needsVehicle(
        buildDispatchLine(
          authorizedReasonCode: DispatchAuthorizationReasonCode.notAssigned,
        ),
      ),
      isFalse,
    );
  });
}
