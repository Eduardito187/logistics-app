import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';

void main() {
  group('SubmitOutcome', () {
    test('tiene exactamente los tres desenlaces del envío offline-first', () {
      // La UI y la cola dependen de que no aparezcan/desaparezcan valores sin
      // que los tests y el feedback se actualicen.
      expect(SubmitOutcome.values, <SubmitOutcome>[
        SubmitOutcome.sent,
        SubmitOutcome.queued,
        SubmitOutcome.failed,
      ]);
    });

    test('los índices son estables (no se reordenan)', () {
      expect(SubmitOutcome.sent.index, 0);
      expect(SubmitOutcome.queued.index, 1);
      expect(SubmitOutcome.failed.index, 2);
    });
  });
}
