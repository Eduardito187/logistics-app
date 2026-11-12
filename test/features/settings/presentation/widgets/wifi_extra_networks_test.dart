import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/token_store.dart';
import 'package:logistics_app/core/printing/extra_network_input.dart';
import 'package:logistics_app/core/printing/extra_networks_notifier.dart';
import 'package:logistics_app/features/settings/presentation/widgets/wifi_extra_networks.dart';

import '../../../../core/auth/test_fakes.dart';
import '../../../../support/screen_sizes.dart';

// "Buscar también en otra red": redes extra que barre la búsqueda WiFi. Vive
// en la ayuda "¿No aparece?" del asistente y en Opciones avanzadas.

Future<void> _pump(
  WidgetTester tester, {
  FakeSecureStorage? storage,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(storage ?? FakeSecureStorage()),
      ],
      child: MaterialApp(
        home: withTextScale(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: WifiExtraNetworks(),
            ),
          ),
          scale: textScale,
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _field() => find.widgetWithText(TextField, 'Red');

Future<void> _add(WidgetTester tester, String text) async {
  await tester.ensureVisible(_field());
  await tester.enterText(_field(), text);
  await tester.tap(find.text('Agregar'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('muestra la ayuda', (tester) async {
    await _pump(tester);

    expect(find.text('Buscar también en otra red'), findsOneWidget);
    expect(
      find.text(
        'Si la impresora está en otra red (ej. la de cable), agregá su '
        'red: los primeros 3 números de su IP.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('agregar "192.168.2" crea el chip y lo guarda', (tester) async {
    final storage = FakeSecureStorage();
    await _pump(tester, storage: storage);

    await _add(tester, '192.168.2');

    expect(find.widgetWithText(InputChip, '192.168.2.0/24'), findsOneWidget);
    expect(
      storage.data[ExtraNetworksNotifier.storageKey],
      '["192.168.2.0/24"]',
    );
    // El campo queda vacío para agregar otra.
    expect(tester.widget<TextField>(_field()).controller!.text, isEmpty);
  });

  testWidgets('red inválida o muy grande: muestra el error', (tester) async {
    await _pump(tester);

    await _add(tester, '192.168');
    expect(find.text(ExtraNetworkInput.formatError), findsOneWidget);

    await _add(tester, '10.20.0.0/16');
    expect(find.text(ExtraNetworkInput.tooBigError), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('carga las guardadas y quitar un chip la borra', (tester) async {
    final storage = FakeSecureStorage()
      ..seed(
        ExtraNetworksNotifier.storageKey,
        '["192.168.2.0/24","10.20.0.0/22"]',
      );
    await _pump(tester, storage: storage);
    await tester.pump();

    expect(find.byType(InputChip), findsNWidgets(2));

    await tester.ensureVisible(find.byTooltip('Quitar 192.168.2.0/24'));
    await tester.tap(find.byTooltip('Quitar 192.168.2.0/24'));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(InputChip, '192.168.2.0/24'), findsNothing);
    expect(find.widgetWithText(InputChip, '10.20.0.0/22'), findsOneWidget);
    expect(storage.data[ExtraNetworksNotifier.storageKey], '["10.20.0.0/22"]');
  });

  testOnScreens('chips de redes no desbordan con letra grande', (
    tester,
    screen,
  ) async {
    final storage = FakeSecureStorage()
      ..seed(
        ExtraNetworksNotifier.storageKey,
        '["192.168.2.0/24","10.20.0.0/22","172.16.100.0/24"]',
      );
    await _pump(tester, storage: storage, textScale: 1.3);
    await tester.pump();

    expect(find.byType(InputChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
