import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/api/models/proof_of_delivery_request.dart';
import 'package:logistics_app/core/api/models/scan_request.dart';
import 'package:logistics_app/core/labels/label_payload.dart';
import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';
import 'package:logistics_app/core/location/location_service.dart';
import 'package:logistics_app/core/offline/submit_outcome.dart';
import 'package:logistics_app/core/scanning/scanner_screen.dart';
import 'package:logistics_app/features/carrier/domain/usecases/record_load_scan.dart';
import 'package:logistics_app/features/carrier/domain/usecases/record_proof_of_delivery.dart';

import '../../support/fake_code_scanner.dart';
import '../store/fake_continuous_scanner.dart';
import 'carrier_test_harness.dart';

// Dobles para los flujos escaneo -> submit del transportista: etiqueta firmada
// real (vector Ed25519 compartido con el backend), GPS fijo y casos de uso de la
// cola offline que solo registran lo recibido.

Map<String, dynamic> _vector() =>
    jsonDecode(File('test/fixtures/label_test_vector.json').readAsStringSync())
        as Map<String, dynamic>;

/// QR válido firmado por el backend.
String validLabelQr() => _vector()['qr_content'] as String;

/// Mismo QR con el pedido editado: la firma ya no corresponde.
String tamperedLabelQr() => _vector()['tampered_qr_content'] as String;

/// Datos esperados del vector (id del bulto, pedido y SKU).
const vectorUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';
const vectorOrder = 'DM-260012345';
const vectorSku = 'LG-GT32WPP';

/// Scanner con la clave pública del vector, sin cliente API (solo offline).
LabelScanner vectorLabelScanner() {
  final vector = _vector();
  return LabelScanner(
    LabelVerifier({
      vector['key_id'] as int: base64.decode(
        vector['public_key_base64'] as String,
      ),
    }),
  );
}

/// Scanner con una clave de OTRO id: la etiqueta del vector queda "desconocida".
LabelScanner unknownKeyLabelScanner() {
  final vector = _vector();
  return LabelScanner(
    LabelVerifier({99: base64.decode(vector['public_key_base64'] as String)}),
  );
}

/// Firma etiquetas de prueba con una clave Ed25519 propia: el vector del
/// backend trae un solo bulto y el escaneo continuo necesita varios distintos.
/// Crear en `setUpAll` (fuera del reloj falso de testWidgets).
class TestLabelSigner {
  TestLabelSigner._(this._keyPair, this._publicKey);

  static const int keyId = 7;

  final SimpleKeyPair _keyPair;
  final List<int> _publicKey;

  static Future<TestLabelSigner> create() async {
    final keyPair = await Ed25519().newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return TestLabelSigner._(keyPair, publicKey.bytes);
  }

  /// Scanner que verifica las etiquetas de este firmante.
  LabelScanner scanner() => LabelScanner(LabelVerifier({keyId: _publicKey}));

  /// Contenido del QR firmado de un bulto.
  Future<String> qr({
    required String id,
    String order = 'DM-1',
    String sku = 'SKU-1',
  }) async {
    final payload = LabelPayload(
      version: LabelPayload.currentVersion,
      type: LabelType.package,
      keyId: keyId,
      id: id,
      orderNumber: order,
      lineNumber: 1,
      sku: sku,
      unit: Fraction(1, 1),
      piece: Fraction(1, 1),
      origin: 'CD-SCZ',
      destination: 'C',
      issuedAt: 1759312800,
    );
    final signature = await Ed25519().sign(
      utf8.encode(payload.canonical()),
      keyPair: _keyPair,
    );
    return jsonEncode({
      'v': payload.version,
      't': 'PKG',
      'k': keyId,
      'id': id,
      'o': order,
      'ln': 1,
      'sku': sku,
      'u': [1, 1],
      'pc': [1, 1],
      'org': 'CD-SCZ',
      'dst': 'C',
      'ts': 1759312800,
      's': base64Url.encode(signature.bytes).replaceAll('=', ''),
    });
  }
}

/// GPS fijo que no toca geolocator.
class FixedLocationService extends LocationService {
  FixedLocationService([this.fix]);

  final GpsFix? fix;

  @override
  Future<GpsFix?> current({
    Duration timeout = const Duration(seconds: 6),
  }) async => fix;
}

/// Caso de uso de recojo que registra lo enviado y devuelve [outcome].
class FakeRecordLoadScan implements RecordLoadScan {
  FakeRecordLoadScan([this.outcome = SubmitOutcome.sent]);

  final SubmitOutcome outcome;
  final List<ScanRequest> requests = [];
  final List<String> labels = [];

  @override
  Future<SubmitOutcome> call({
    required ScanRequest request,
    required String label,
  }) async {
    requests.add(request);
    labels.add(label);
    return outcome;
  }
}

/// Caso de uso de prueba de entrega que registra lo enviado.
class FakeRecordProofOfDelivery implements RecordProofOfDelivery {
  FakeRecordProofOfDelivery([this.outcome = SubmitOutcome.sent]);

  final SubmitOutcome outcome;
  final List<ProofOfDeliveryRequest> requests = [];
  final List<String> labels = [];

  @override
  Future<SubmitOutcome> call({
    required ProofOfDeliveryRequest request,
    required String label,
  }) async {
    requests.add(request);
    labels.add(label);
    return outcome;
  }
}

/// Monta [screen] con los escáneres falsos (un código: confirmación del
/// cliente; continuo: bultos) y los dobles de verificación/GPS/cola.
Future<void> pumpCarrierScanScreen(
  WidgetTester tester,
  Widget screen, {
  FakeCodeScanner? scanner,
  FakeContinuousScanner? continuous,
  LabelScanner? labelScanner,
  FakeRecordLoadScan? loadScan,
  FakeRecordProofOfDelivery? proofOfDelivery,
  GpsFix? fix,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...syncBadgeOverrides(),
        codeScannerProvider.overrideWithValue(
          (scanner ?? FakeCodeScanner(const [])).call,
        ),
        continuousScannerProvider.overrideWithValue(
          (continuous ?? FakeContinuousScanner(const [])).call,
        ),
        labelScannerProvider.overrideWithValue(
          labelScanner ?? vectorLabelScanner(),
        ),
        locationServiceProvider.overrideWithValue(FixedLocationService(fix)),
        recordLoadScanProvider.overrideWithValue(
          loadScan ?? FakeRecordLoadScan(),
        ),
        recordProofOfDeliveryProvider.overrideWithValue(
          proofOfDelivery ?? FakeRecordProofOfDelivery(),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}
