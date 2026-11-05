import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/sharing/capture_boundary.dart';
import 'package:logistics_app/core/sharing/share_service.dart';
import 'package:logistics_app/core/theme/app_theme.dart';
import 'package:logistics_app/features/picking/presentation/widgets/label_preview_sheet.dart';
import 'package:logistics_app/features/store/presentation/widgets/pickup_pod_cards.dart';

import '../../support/fake_share_service.dart';
import '../picking/picking_test_harness.dart';

/// Captura falsa: devuelve bytes fijos sin rasterizar (determinista en tests).
BoundaryCapturer _fakeCapture(List<int> bytes) =>
    (key, {double pixelRatio = 3.0}) async => Uint8List.fromList(bytes);

void main() {
  testWidgets('el preview de etiqueta comparte el PNG por el menú nativo', (
    tester,
  ) async {
    final share = FakeShareService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareServiceProvider.overrideWithValue(share),
          boundaryCapturerProvider.overrideWithValue(
            _fakeCapture(const [1, 2, 3, 4]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showLabelPreviewSheet(
                    context,
                    label: buildLabel(
                      orderNumber: 'EXT-9',
                      sku: 'SKU9',
                      lineNumber: 2,
                    ),
                    productName: 'Heladera',
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // El botón Compartir está presente y destacado.
    expect(find.text('Compartir'), findsOneWidget);

    await tester.tap(find.text('Compartir'));
    await tester.pumpAndSettle();

    expect(share.shared, hasLength(1));
    final item = share.shared.single;
    expect(item.isPng, isTrue);
    expect(item.bytes, isNotEmpty);
    expect(item.filename, contains('EXT-9'));
    expect(item.text, contains('EXT-9'));
    expect(item.text, contains('Heladera'));
  });

  testWidgets('la foto de recojo en tienda muestra Compartir cuando hay foto', (
    tester,
  ) async {
    var shared = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PickupPhotoCard(
            photo: File('no-existe.png'),
            busy: false,
            onTakePhoto: () {},
            onShare: () => shared = true,
          ),
        ),
      ),
    );
    await tester.pump();

    final compartir = find.text('Compartir');
    expect(compartir, findsOneWidget);
    await tester.tap(compartir);
    expect(shared, isTrue);
  });

  testWidgets('sin foto, recojo en tienda no ofrece Compartir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PickupPhotoCard(
            photo: null,
            busy: false,
            onTakePhoto: () {},
            onShare: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Compartir'), findsNothing);
  });
}
