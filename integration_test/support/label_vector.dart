import 'dart:convert';

import 'package:logistics_app/core/labels/label_scanner.dart';
import 'package:logistics_app/core/labels/label_verifier.dart';

// Vector Ed25519 compartido con el backend, embebido como constantes: en el
// dispositivo no existe `test/fixtures/label_test_vector.json` (los tests de
// integración corren dentro del APK), así que no se puede leer con `File`.
// Si el backend regenera el vector, actualizar también estas constantes
// (`test/core/labels/label_test_vector_test.dart` valida el JSON).

const vectorKeyId = 1;

const vectorPublicKeyBase64 = 'zOoO3DEULPdeVHmozqu0xm6E8njSdpO0jIZN7y+K/yo=';

/// `unit_id` que trae el QR firmado del vector.
const vectorUnitId = '01JB8ZQ4X7K2M9N5P6R7S8T9VW';

/// QR de etiqueta con firma válida.
const validLabelQr =
    '{"v":1,"t":"PKG","k":1,"id":"01JB8ZQ4X7K2M9N5P6R7S8T9VW",'
    '"o":"DM-260012345","ln":3,"sku":"LG-GT32WPP","u":[1,2],"pc":[1,1],'
    '"org":"CD-SCZ","dst":"C","ts":1759312800,'
    '"s":"vGUuqT7zusA-xPjt0iW0TSy6i8F5QojH3ajEFLQ5b3Mf5ze9QOzTT1MHCk-9QnWYil2H5Hj9cBcC2awgauFADw"}';

/// El mismo QR con el pedido alterado: la firma ya no verifica.
const tamperedLabelQr =
    '{"v":1,"t":"PKG","k":1,"id":"01JB8ZQ4X7K2M9N5P6R7S8T9VW",'
    '"o":"DM-260099999","ln":3,"sku":"LG-GT32WPP","u":[1,2],"pc":[1,1],'
    '"org":"CD-SCZ","dst":"C","ts":1759312800,'
    '"s":"vGUuqT7zusA-xPjt0iW0TSy6i8F5QojH3ajEFLQ5b3Mf5ze9QOzTT1MHCk-9QnWYil2H5Hj9cBcC2awgauFADw"}';

/// Claves públicas como las entrega `labelKeysProvider` (id → bytes).
Map<int, List<int>> vectorKeys() => {
  vectorKeyId: base64.decode(vectorPublicKeyBase64),
};

/// Verificador offline con la clave del vector y SIN cliente API (el reporte
/// best-effort de escaneos al backend no aplica en el e2e).
LabelScanner vectorLabelScanner() => LabelScanner(LabelVerifier(vectorKeys()));
