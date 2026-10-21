import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/scanning/scan_feedback.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/core/theme/high_contrast.dart';
import 'package:logistics_app/features/settings/presentation/widgets/field_use_section.dart';

import '../../../../core/auth/test_fakes.dart';

// Sección "Uso en terreno" de Ajustes: switches de alto contraste (default
// OFF) y de vibrar/sonar al escanear (default ON); cada cambio se guarda.

Future<(ProviderContainer, FakeSecureStorage)> _pump(
  WidgetTester tester, {
  FakeSecureStorage? storage,
}) async {
  final store = storage ?? FakeSecureStorage();
  final container = ProviderContainer(
    overrides: [secureStorageProvider.overrideWithValue(store)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(child: FieldUseSection()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (container, store);
}

bool _switchValue(WidgetTester tester, String key) =>
    tester.widget<SwitchListTile>(find.byKey(Key(key))).value;

void main() {
  testWidgets('muestra las dos opciones con sus valores por defecto', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Uso en terreno'), findsOneWidget);
    expect(find.text('Alto contraste (sol)'), findsOneWidget);
    expect(find.text('Vibrar y sonar al escanear'), findsOneWidget);
    expect(_switchValue(tester, 'highContrastSwitch'), isFalse);
    expect(_switchValue(tester, 'scanFeedbackSwitch'), isTrue);
  });

  testWidgets('activar alto contraste cambia el provider y lo guarda', (
    tester,
  ) async {
    final (container, storage) = await _pump(tester);
    await tester.tap(find.text('Alto contraste (sol)'));
    await tester.pumpAndSettle();
    expect(container.read(highContrastProvider), isTrue);
    expect(_switchValue(tester, 'highContrastSwitch'), isTrue);
    expect(storage.data[HighContrastNotifier.storageKey], 'true');
  });

  testWidgets('desactivar el aviso al escanear lo guarda', (tester) async {
    final (container, storage) = await _pump(tester);
    await tester.tap(find.text('Vibrar y sonar al escanear'));
    await tester.pumpAndSettle();
    expect(container.read(scanFeedbackEnabledProvider), isFalse);
    expect(storage.data[ScanFeedbackEnabledNotifier.storageKey], 'false');
  });

  testWidgets('refleja lo guardado al abrir', (tester) async {
    final storage = FakeSecureStorage()
      ..seed(HighContrastNotifier.storageKey, 'true')
      ..seed(ScanFeedbackEnabledNotifier.storageKey, 'false');
    await _pump(tester, storage: storage);
    expect(_switchValue(tester, 'highContrastSwitch'), isTrue);
    expect(_switchValue(tester, 'scanFeedbackSwitch'), isFalse);
  });

  testWidgets('los switches miden al menos 48 dp de alto', (tester) async {
    await _pump(tester);
    for (final key in ['highContrastSwitch', 'scanFeedbackSwitch']) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
  });
}
