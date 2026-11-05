import 'dart:typed_data';

import 'package:logistics_app/core/sharing/share_service.dart';

/// Doble de [ShareService] para tests: NO abre el menú del sistema; registra lo
/// que se compartió para poder verificarlo.
class FakeShareService implements ShareService {
  final List<SharedItem> shared = <SharedItem>[];

  @override
  Future<void> shareImagePng(
    Uint8List bytes, {
    required String filename,
    String? text,
  }) async {
    shared.add(SharedItem.png(filename: filename, text: text, bytes: bytes));
  }

  @override
  Future<void> shareFile(String path, {String? text}) async {
    shared.add(SharedItem.file(path: path, text: text));
  }
}

/// Un elemento compartido registrado por [FakeShareService].
class SharedItem {
  const SharedItem.png({
    required this.filename,
    required this.text,
    required this.bytes,
  }) : path = null;

  const SharedItem.file({required this.path, required this.text})
    : filename = null,
      bytes = null;

  final String? filename;
  final String? path;
  final String? text;
  final Uint8List? bytes;

  bool get isPng => filename != null;
}
