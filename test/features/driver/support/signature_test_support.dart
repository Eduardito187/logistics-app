import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/features/driver/data/datasources/signature_file_store.dart';
import 'package:logistics_app/features/driver/presentation/signature_pad_screen.dart';

// Soporte de la firma digital del cliente en el POD: PNG mínimo válido, store
// de archivos falso (sin path_provider ni disco) y helper para firmar en el pad.

/// PNG 1x1 válido (lo que devuelve el exportador falso).
final Uint8List kTinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Store de firmas falso: registra lo guardado y lo descartado.
class FakeSignatureFileStore implements SignatureFileStore {
  FakeSignatureFileStore({this.path = '/tmp/firma.png'});

  final String path;
  final List<Uint8List> saved = [];
  final List<String> discarded = [];

  @override
  Future<String> save(Uint8List png) async {
    saved.add(png);
    return path;
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

/// Overrides de la firma: exportador que devuelve [png] (sin rasterizar) y el
/// store falso.
List<Object> signatureOverrides(
  FakeSignatureFileStore store, {
  Uint8List? png,
}) => [
  signaturePngExporterProvider.overrideWithValue(
    (controller) async => controller.isEmpty ? null : (png ?? kTinyPng),
  ),
  signatureFileStoreProvider.overrideWithValue(store),
];

/// Traza una firma con el dedo sobre el pad abierto.
Future<void> drawOnPad(WidgetTester tester) async {
  final pad = find.byKey(const ValueKey('signature-pad'));
  await tester.drag(pad, const Offset(160, 40));
  await tester.pump();
}

/// Abre el pad desde el POD, firma y confirma con "Listo".
Future<void> signOnPad(WidgetTester tester) async {
  await tester.tap(find.text('Firma del cliente'));
  await tester.pumpAndSettle();
  await drawOnPad(tester);
  await tester.tap(find.text('Listo'));
  await tester.pumpAndSettle();
}
