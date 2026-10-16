import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/commands/command_status.dart';

void main() {
  group('CommandStatus', () {
    test('tiene exactamente applied y accepted, en ese orden', () {
      expect(CommandStatus.values, <CommandStatus>[
        CommandStatus.applied,
        CommandStatus.accepted,
      ]);
    });
  });
}
