import 'package:image_picker/image_picker.dart';

/// Cámara falsa para widget tests: devuelve las rutas de [paths] en orden (un
/// `null` simula que el usuario canceló) y registra lo pedido.
///
/// Uso: `photoPickerProvider.overrideWithValue(fake.call)`.
class FakePhotoPicker {
  FakePhotoPicker(Iterable<String?> paths) : _paths = List.of(paths);

  final List<String?> _paths;

  /// maxWidth/imageQuality de cada pedido (para verificar que se reduce).
  final List<({double maxWidth, int imageQuality})> requests = [];

  Future<XFile?> call({
    required double maxWidth,
    required int imageQuality,
  }) async {
    requests.add((maxWidth: maxWidth, imageQuality: imageQuality));
    if (_paths.isEmpty) return null;
    final path = _paths.removeAt(0);
    return path == null ? null : XFile(path);
  }
}
