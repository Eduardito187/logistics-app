import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:usb_serial/usb_serial.dart';

import '../auth/token_store.dart';
import 'printer_config.dart';

/// Impresión de etiquetas ZPL agnóstica del transporte.
///
/// Envía los bytes del ZPL por Bluetooth, WiFi o USB según la impresora
/// seleccionada (o la pasada en [printZpl]). El mismo ZPL sirve para los tres:
/// el transporte solo cambia cómo llegan los bytes a la Zebra.
class LabelPrinter {
  LabelPrinter(this._storage);

  final FlutterSecureStorage _storage;
  static const _selectedKey = 'label_printer_config';

  /// Impresora seleccionada y persistida en almacenamiento seguro, o null.
  Future<PrinterConfig?> selectedPrinter() async {
    final raw = await _storage.read(key: _selectedKey);
    return PrinterConfig.decode(raw);
  }

  /// Persiste la impresora elegida por el usuario.
  Future<void> selectPrinter(PrinterConfig config) =>
      _storage.write(key: _selectedKey, value: config.encode());

  /// Descubre impresoras disponibles por [transport].
  ///
  /// - bluetooth: dispositivos emparejados en el sistema.
  /// - usb: dispositivos USB conectados ([UsbSerial.listDevices]).
  /// - wifi: no hay descubrimiento; el usuario ingresa `ip:puerto` a mano.
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async {
    switch (transport) {
      case PrinterTransport.bluetooth:
        return _bondedBluetooth();
      case PrinterTransport.usb:
        return _connectedUsb();
      case PrinterTransport.wifi:
        return const <PrinterDevice>[];
    }
  }

  /// Envía ZPL crudo a la impresora [to] (o a la seleccionada si es null).
  /// Lanza [PrinterException] con mensaje claro ante cualquier falla.
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {
    final target = to ?? await selectedPrinter();
    if (target == null) {
      throw const PrinterException('No hay impresora seleccionada.');
    }
    final bytes = Uint8List.fromList(utf8.encode(zpl));
    switch (target.transport) {
      case PrinterTransport.bluetooth:
        await _printBluetooth(target, bytes);
      case PrinterTransport.wifi:
        await _printWifi(target, bytes);
      case PrinterTransport.usb:
        await _printUsb(target, bytes);
    }
  }

  // --- Bluetooth (flutter_blue_plus) --------------------------------------

  Future<List<PrinterDevice>> _bondedBluetooth() async {
    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      return bonded
          .where((d) => d.platformName.isNotEmpty)
          .map(
            (d) => PrinterDevice(
              transport: PrinterTransport.bluetooth,
              address: d.remoteId.str,
              name: d.platformName,
            ),
          )
          .toList();
    } on Exception {
      return const <PrinterDevice>[];
    }
  }

  /// Las Zebra exponen una característica de escritura donde se vuelca ZPL
  /// crudo. Se envía en trozos para no exceder el MTU BLE.
  Future<void> _printBluetooth(PrinterConfig config, Uint8List bytes) async {
    final device = BluetoothDevice.fromId(config.address);
    try {
      await device.connect(timeout: const Duration(seconds: 12));
      final services = await device.discoverServices();
      final characteristic = _findWritable(services);
      if (characteristic == null) {
        throw const PrinterException(
          'La impresora no expone un canal de escritura ZPL.',
        );
      }
      const chunk = 180;
      final withoutResponse = characteristic.properties.writeWithoutResponse;
      for (var i = 0; i < bytes.length; i += chunk) {
        final end = (i + chunk < bytes.length) ? i + chunk : bytes.length;
        await characteristic.write(
          bytes.sublist(i, end),
          withoutResponse: withoutResponse,
        );
      }
    } on PrinterException {
      rethrow;
    } on Exception catch (e) {
      throw PrinterException('No se pudo imprimir por Bluetooth: $e');
    } finally {
      unawaited(device.disconnect());
    }
  }

  BluetoothCharacteristic? _findWritable(List<BluetoothService> services) {
    for (final service in services) {
      for (final c in service.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          return c;
        }
      }
    }
    return null;
  }

  // --- WiFi (socket TCP raw / JetDirect, puerto 9100) ---------------------

  Future<void> _printWifi(PrinterConfig config, Uint8List bytes) async {
    final host = config.wifiHost;
    if (host.isEmpty) {
      throw const PrinterException(
        'La impresora WiFi no tiene IP configurada.',
      );
    }
    Socket? socket;
    try {
      socket = await Socket.connect(
        host,
        config.wifiPort,
        timeout: const Duration(seconds: 8),
      );
      socket.add(bytes);
      await socket.flush();
    } on SocketException catch (e) {
      throw PrinterException(
        'No se pudo conectar a $host:${config.wifiPort} ($e).',
      );
    } on Exception catch (e) {
      throw PrinterException('No se pudo imprimir por WiFi: $e');
    } finally {
      await socket?.close();
    }
  }

  // --- USB (usb_serial) ---------------------------------------------------

  Future<List<PrinterDevice>> _connectedUsb() async {
    try {
      final devices = await UsbSerial.listDevices();
      return devices
          .where((d) => d.vid != null && d.pid != null)
          .map(
            (d) => PrinterDevice(
              transport: PrinterTransport.usb,
              address: '${d.vid}:${d.pid}',
              name: d.productName ?? d.manufacturerName ?? d.deviceName,
            ),
          )
          .toList();
    } on Exception {
      return const <PrinterDevice>[];
    }
  }

  Future<void> _printUsb(PrinterConfig config, Uint8List bytes) async {
    final vid = config.usbVendorId;
    final pid = config.usbProductId;
    if (vid == null || pid == null) {
      throw const PrinterException('La impresora USB no está identificada.');
    }
    UsbPort? port;
    try {
      port = await UsbSerial.create(vid, pid);
      if (port == null) {
        throw const PrinterException(
          'No se encontró la impresora USB (¿conectada y con permiso?).',
        );
      }
      final opened = await port.open();
      if (!opened) {
        throw const PrinterException('No se pudo abrir el puerto USB.');
      }
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      await port.write(bytes);
    } on PrinterException {
      rethrow;
    } on Exception catch (e) {
      throw PrinterException('No se pudo imprimir por USB: $e');
    } finally {
      await port?.close();
    }
  }
}

final labelPrinterProvider = Provider<LabelPrinter>(
  (ref) => LabelPrinter(ref.watch(secureStorageProvider)),
);
