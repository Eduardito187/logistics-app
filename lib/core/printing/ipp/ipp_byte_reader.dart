import 'dart:typed_data';

/// Lector secuencial big-endian con control de límites: si los bytes se
/// acaban antes de tiempo lanza [FormatException] (respuesta truncada).
class IppByteReader {
  IppByteReader(this._bytes);

  final Uint8List _bytes;
  int _offset = 0;

  bool get done => _offset >= _bytes.length;

  void _need(int n) {
    if (_offset + n > _bytes.length) {
      throw const FormatException('Respuesta IPP truncada');
    }
  }

  int u8() {
    _need(1);
    return _bytes[_offset++];
  }

  int u16() {
    _need(2);
    final v = (_bytes[_offset] << 8) | _bytes[_offset + 1];
    _offset += 2;
    return v;
  }

  int u32() {
    _need(4);
    final v = ByteData.sublistView(_bytes, _offset, _offset + 4).getUint32(0);
    _offset += 4;
    return v;
  }

  Uint8List bytes(int n) {
    _need(n);
    final out = Uint8List.sublistView(_bytes, _offset, _offset + n);
    _offset += n;
    return out;
  }

  Uint8List rest() {
    final out = Uint8List.sublistView(_bytes, _offset);
    _offset = _bytes.length;
    return out;
  }
}
