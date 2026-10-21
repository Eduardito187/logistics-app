import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Toma una foto con la cámara y devuelve el archivo, o `null` si se canceló.
///
/// [maxWidth] y [imageQuality] acotan el tamaño: en teléfonos de 1 GB de RAM
/// una foto de 12 MP sin reducir se decodifica en ~48 MB y puede tumbar la app.
typedef PhotoPicker =
    Future<XFile?> Function({
      required double maxWidth,
      required int imageQuality,
    });

/// Valores por defecto para fotos de evidencia (POD, daños, entrega fallida):
/// legibles para el backend y livianos para memoria y datos móviles.
const double kEvidencePhotoMaxWidth = 1600;
const int kEvidencePhotoQuality = 70;

/// Cámara del dispositivo. En widget tests se reemplaza con
/// `photoPickerProvider.overrideWithValue(fake.call)` (ver
/// `test/support/fake_photo_picker.dart`) para ejercitar los flujos con foto.
final photoPickerProvider = Provider<PhotoPicker>(
  (ref) =>
      ({required double maxWidth, required int imageQuality}) =>
          ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: maxWidth,
            imageQuality: imageQuality,
          ),
);
