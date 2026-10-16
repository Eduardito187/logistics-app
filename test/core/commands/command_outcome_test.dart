import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/accepted_envelope.dart';
import 'package:logistics_app/core/api/models/data21.dart';
// command_outcome.dart reexporta command_status.dart (CommandStatus).
import 'package:logistics_app/core/commands/command_outcome.dart';

void main() {
  group('CommandOutcome.applied', () {
    test('status applied y banderas coherentes', () {
      const outcome = CommandOutcome.applied();
      expect(outcome.status, CommandStatus.applied);
      expect(outcome.isApplied, isTrue);
      expect(outcome.isAccepted, isFalse);
      expect(outcome.message, isNull);
    });

    test('conserva el mensaje propio del backend si lo hay', () {
      const outcome = CommandOutcome.applied(message: 'Pago confirmado.');
      expect(outcome.message, 'Pago confirmado.');
      expect(outcome.isApplied, isTrue);
    });
  });

  group('CommandOutcome.accepted', () {
    test('status accepted y banderas coherentes', () {
      const outcome = CommandOutcome.accepted();
      expect(outcome.status, CommandStatus.accepted);
      expect(outcome.isAccepted, isTrue);
      expect(outcome.isApplied, isFalse);
      expect(outcome.message, isNull);
    });

    test('conserva el mensaje propio del backend si lo hay', () {
      const outcome = CommandOutcome.accepted(message: 'En cola de proceso.');
      expect(outcome.message, 'En cola de proceso.');
      expect(outcome.isAccepted, isTrue);
    });
  });

  group('CommandOutcome.fromAccepted', () {
    test(
      'un envelope 202 con accepted:true produce un accepted sin mensaje',
      () {
        final outcome = CommandOutcome.fromAccepted(
          const AcceptedEnvelope(data: Data21(accepted: true)),
        );
        expect(outcome.status, CommandStatus.accepted);
        expect(outcome.isAccepted, isTrue);
        // El envelope no trae copy propio: la UI usará su texto por defecto.
        expect(outcome.message, isNull);
      },
    );

    test(
      'un envelope con accepted:false dispara el assert (contrato roto)',
      () {
        // En debug/tests los asserts están activos: un 202 que NO acepta es un
        // error de contrato del backend y debe fallar ruidosamente.
        expect(
          () => CommandOutcome.fromAccepted(
            const AcceptedEnvelope(data: Data21(accepted: false)),
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
