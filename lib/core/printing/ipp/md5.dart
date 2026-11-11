import 'dart:math' as math;
import 'dart:typed_data';

/// MD5 (RFC 1321) en Dart puro, SOLO para la autenticación HTTP Digest que
/// piden algunas impresoras (Ricoh, HP). No es para seguridad propia de la app
/// (MD5 está roto para eso); la app no suma paquetes para esto.
abstract final class Md5 {
  static const List<int> _shifts = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, //
    5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, //
    4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, //
    6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
  ];

  static final List<int> _k = List<int>.generate(
    64,
    (i) => (math.sin(i + 1).abs() * 4294967296).floor() & 0xFFFFFFFF,
  );

  static const int _mask = 0xFFFFFFFF;

  static int _rotl(int x, int c) => ((x << c) | (x >> (32 - c))) & _mask;

  /// Digest de 16 bytes.
  static Uint8List hash(List<int> input) {
    final length = input.length;
    final padded = ((length + 8) ~/ 64 + 1) * 64;
    final msg = Uint8List(padded)..setRange(0, length, input);
    msg[length] = 0x80;
    final view = ByteData.sublistView(msg);
    final bits = length * 8;
    view
      ..setUint32(padded - 8, bits & _mask, Endian.little)
      ..setUint32(padded - 4, (bits ~/ 0x100000000) & _mask, Endian.little);

    var a0 = 0x67452301;
    var b0 = 0xefcdab89;
    var c0 = 0x98badcfe;
    var d0 = 0x10325476;
    final m = List<int>.filled(16, 0);
    for (var chunk = 0; chunk < padded; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        m[i] = view.getUint32(chunk + i * 4, Endian.little);
      }
      var a = a0;
      var b = b0;
      var c = c0;
      var d = d0;
      for (var i = 0; i < 64; i++) {
        int f;
        int g;
        if (i < 16) {
          f = (b & c) | ((~b & _mask) & d);
          g = i;
        } else if (i < 32) {
          f = (d & b) | ((~d & _mask) & c);
          g = (5 * i + 1) % 16;
        } else if (i < 48) {
          f = b ^ c ^ d;
          g = (3 * i + 5) % 16;
        } else {
          f = c ^ (b | (~d & _mask));
          g = (7 * i) % 16;
        }
        f = (f + a + _k[i] + m[g]) & _mask;
        a = d;
        d = c;
        c = b;
        b = (b + _rotl(f, _shifts[i])) & _mask;
      }
      a0 = (a0 + a) & _mask;
      b0 = (b0 + b) & _mask;
      c0 = (c0 + c) & _mask;
      d0 = (d0 + d) & _mask;
    }
    final out = ByteData(16)
      ..setUint32(0, a0, Endian.little)
      ..setUint32(4, b0, Endian.little)
      ..setUint32(8, c0, Endian.little)
      ..setUint32(12, d0, Endian.little);
    return out.buffer.asUint8List();
  }

  /// Digest en hexadecimal minúscula (como lo pide HTTP Digest).
  static String hex(List<int> input) =>
      hash(input).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
