import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usb_serial/usb_serial.dart';

import '../auth/session_notifier.dart';
import '../auth/token_store.dart';
import 'office/label_raster.dart';
import 'office/label_renderer.dart';
import 'office/office_printer.dart';
import 'print_outcome.dart';
import 'printer_config.dart';
import 'printer_credentials.dart';
import 'printer_credentials_store.dart';
import 'wifi_printer_scanner.dart';
import 'zebra_status.dart';

export 'office/label_raster.dart';
export 'office/label_renderer.dart';
export 'print_outcome.dart';

/// Impresión de etiquetas agnóstica del transporte y del tipo de impresora.
///
/// - Zebra (ZPL): manda el ZPL por Bluetooth, WiFi (9100) o USB. Por WiFi,
///   después pregunta el estado (`~HS`) por la misma conexión: si la Zebra
///   contesta, se sabe si quedó sin papel, en pausa o con el cabezal abierto.
/// - Oficina (Ricoh, HP…): NO entiende ZPL. La etiqueta se dibuja como imagen
///   ([LabelRenderer]) y va como PDF/PWG por IPP (con usuario y contraseña de
///   la impresora y confirmación del trabajo) o como PCL por el 9100.
class LabelPrinter {
  LabelPrinter(
    this._storage, {
    WifiPrinterScanner? wifiScanner,
    OfficePrinter? officePrinter,
    PrinterCredentialsStore? credentials,
    String? Function()? currentUser,
    Duration zebraStatusTimeout = const Duration(seconds: 2),
  }) : _wifiScanner = wifiScanner,
       _office = officePrinter ?? OfficePrinter(),
       _credentials = credentials ?? PrinterCredentialsStore(_storage),
       _currentUser = currentUser,
       _zebraStatusTimeout = zebraStatusTimeout;

  final FlutterSecureStorage _storage;
  final OfficePrinter _office;
  final PrinterCredentialsStore _credentials;

  /// Usuario de la sesión (para `requesting-user-name`/PJL si la impresora no
  /// tiene credenciales propias).
  final String? Function()? _currentUser;

  /// Cuánto se espera la respuesta de estado de una Zebra por WiFi.
  final Duration _zebraStatusTimeout;

  /// Búsqueda en la red para re-localizar una impresora WiFi cuya IP cambió.
  /// `null` = sin re-localización (tests, ingreso manual).
  final WifiPrinterScanner? _wifiScanner;

  /// Clave de la impresora activa en el almacén seguro (Ajustes la borra al
  /// "Olvidar impresora").
  static const selectedKey = 'label_printer_config';

  /// Impresora seleccionada y persistida en almacenamiento seguro, o null.
  Future<PrinterConfig?> selectedPrinter() async {
    final raw = await _storage.read(key: selectedKey);
    return PrinterConfig.decode(raw);
  }

  /// Persiste la impresora elegida por el usuario.
  Future<void> selectPrinter(PrinterConfig config) =>
      _storage.write(key: selectedKey, value: config.encode());

  /// Descubre impresoras disponibles por [transport].
  ///
  /// - bluetooth: dispositivos emparejados en el sistema.
  /// - usb: dispositivos USB conectados ([UsbSerial.listDevices]).
  /// - wifi: barrido completo de la red local (bloquea hasta terminar). La UI
  ///   usa [WifiPrinterScanner.scan] directo para mostrar el avance en vivo.
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async {
    switch (transport) {
      case PrinterTransport.bluetooth:
        return _bondedBluetooth();
      case PrinterTransport.usb:
        return _connectedUsb();
      case PrinterTransport.wifi:
        return _scanWifi();
    }
  }

  Future<List<PrinterDevice>> _scanWifi() async {
    final scanner = _wifiScanner;
    if (scanner == null) return const <PrinterDevice>[];
    try {
      final last = await scanner.scan().last;
      return [
        for (final hit in last.found)
          PrinterDevice(
            transport: PrinterTransport.wifi,
            address: hit.address,
            name: hit.toConfig().label,
          ),
      ];
    } on Object {
      return const <PrinterDevice>[];
    }
  }

  /// Imprime una etiqueta en la impresora [to] (o en la seleccionada).
  ///
  /// [zpl] va a las Zebra. [render] dibuja la etiqueta como imagen para las
  /// impresoras de oficina (obligatorio para ellas). [jobName] es el nombre
  /// del trabajo que ve la impresora (p. ej. "Etiqueta 1234").
  ///
  /// Devuelve qué se sabe del trabajo ([PrintOutcome], texto veraz) o lanza
  /// [PrinterException] con un mensaje claro.
  Future<PrintOutcome> printLabel({
    required String zpl,
    LabelRenderer? render,
    String? jobName,
    PrinterConfig? to,
  }) async {
    final target = to ?? await selectedPrinter();
    if (target == null) throw PrinterException.notSelected;
    final persist = to == null;
    if (target.isOffice) {
      return _printOffice(
        target,
        render: render,
        jobName: jobName ?? 'Etiqueta DisTrack',
        persistRelocation: persist,
      );
    }
    final bytes = Uint8List.fromList(utf8.encode(zpl));
    switch (target.transport) {
      case PrinterTransport.bluetooth:
        await _printBluetooth(target, bytes);
        return const PrintOutcome.sent();
      case PrinterTransport.wifi:
        return _printWifi(
          target,
          (config) => _sendZpl(config.wifiHost, config.wifiPort, bytes),
          persistRelocation: persist,
        );
      case PrinterTransport.usb:
        await _printUsb(target, bytes);
        return const PrintOutcome.sent();
    }
  }

  /// Compatibilidad: envía ZPL crudo (Zebra). Ante una impresora de oficina
  /// falla con un mensaje claro (sin dibujo de la etiqueta no hay qué mandar).
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {
    await printLabel(zpl: zpl, to: to);
  }

  // --- Oficina (IPP / PCL) ------------------------------------------------

  Future<PrintOutcome> _printOffice(
    PrinterConfig target, {
    required LabelRenderer? render,
    required String jobName,
    required bool persistRelocation,
  }) async {
    if (target.transport != PrinterTransport.wifi) {
      throw const PrinterException(
        'Las impresoras de oficina se usan por WiFi. Elegila en Ajustes › '
        'Impresora › WiFi.',
        needsSetup: true,
      );
    }
    if (render == null) {
      throw const PrinterException(
        'Esta impresora no imprime etiquetas Zebra; desde acá no se puede '
        'generar la página para impresora de oficina. Usá una Zebra o '
        'imprimí desde la vista previa de la etiqueta.',
      );
    }
    final credentials = await _credentials.read(target.address);
    final userName = _userName(credentials);
    final LabelRaster raster;
    try {
      raster = await render();
    } on Object {
      throw const PrinterException(
        'No se pudo preparar la página para la impresora de oficina.',
      );
    }
    return _printWifi(
      target,
      (config) => _office.print(
        config,
        raster,
        jobName: jobName,
        userName: userName,
        credentials: credentials,
      ),
      persistRelocation: persistRelocation,
      credentials: credentials,
    );
  }

  /// Usuario que se informa a la impresora: el de sus credenciales; si no,
  /// el de la sesión (parte local del email); si no, "distrack".
  String _userName(PrinterCredentials? credentials) {
    final own = credentials?.username.trim() ?? '';
    if (own.isNotEmpty) return own;
    String? session;
    try {
      session = _currentUser?.call();
    } on Object {
      session = null;
    }
    final user = (session ?? '').trim();
    if (user.isEmpty) return 'distrack';
    final at = user.indexOf('@');
    return at > 0 ? user.substring(0, at) : user;
  }

  // --- Bluetooth (flutter_blue_plus) --------------------------------------

  Future<List<PrinterDevice>> _bondedBluetooth() async {
    try {
      // Android 12+: `bondedDevices` exige el permiso BLUETOOTH_CONNECT en
      // runtime; sin él, el canal nativo lanza SecurityException. Se pide; si no
      // se concede, se devuelve vacío SIN consultar (nada de excepción suelta).
      if (Platform.isAndroid) {
        final status = await Permission.bluetoothConnect.request();
        if (!status.isGranted) {
          return const <PrinterDevice>[];
        }
      }
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
      // UnsupportedError: plataforma sin Bluetooth (escritorio, tests).
    } on Exception {
      return const <PrinterDevice>[];
    } on UnsupportedError {
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
    } on UnsupportedError catch (e) {
      throw PrinterException('No se pudo imprimir por Bluetooth: $e');
    } finally {
      // Sin plugin, disconnect también falla: no debe escaparse como error suelto.
      unawaited(device.disconnect().catchError((Object _) {}));
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

  /// Imprime por WiFi con [send]. Si la impresora no responde y se eligió
  /// por búsqueda automática (tiene nombre identificado), la vuelve a buscar
  /// en la red por su nombre —como Windows cuando el router le cambia la IP—,
  /// imprime en la nueva dirección y, si era la seleccionada
  /// ([persistRelocation]), la guarda (con sus credenciales).
  Future<PrintOutcome> _printWifi(
    PrinterConfig config,
    Future<PrintOutcome> Function(PrinterConfig config) send, {
    required bool persistRelocation,
    PrinterCredentials? credentials,
  }) async {
    final host = config.wifiHost;
    if (host.isEmpty) {
      throw const PrinterException(
        'La impresora WiFi no tiene IP configurada.',
        needsSetup: true,
      );
    }
    try {
      return await send(config);
    } on PrinterException {
      rethrow;
    } on SocketException catch (e) {
      final moved = await _relocateWifi(config);
      if (moved == null) {
        final where = config.isOffice && config.protocol == PrinterProtocol.ipp
            ? '$host por IPP'
            : '$host:${config.wifiPort}';
        throw PrinterException('No se pudo conectar a $where ($e).');
      }
      final PrintOutcome outcome;
      try {
        outcome = await send(moved);
      } on PrinterException {
        rethrow;
      } on Exception catch (e2) {
        throw PrinterException('No se pudo imprimir por WiFi: $e2');
      }
      if (persistRelocation) {
        try {
          await selectPrinter(moved);
          if (credentials != null) {
            await _credentials.write(moved.address, credentials);
          }
        } on Object {
          // Ya imprimió; la próxima vez se vuelve a re-localizar.
        }
      }
      return outcome;
    } on Exception catch (e) {
      throw PrinterException('No se pudo imprimir por WiFi: $e');
    }
  }

  /// Manda el ZPL y, por la misma conexión, `~HS` (estado). Si la Zebra
  /// contesta a tiempo se reporta lista o el problema (papel,
  /// cabezal, cinta, pausa); si no, "enviado sin confirmación".
  Future<PrintOutcome> _sendZpl(String host, int port, Uint8List bytes) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 8),
    );
    final received = <int>[];
    final answered = Completer<void>();
    void finish() {
      if (!answered.isCompleted) answered.complete();
    }

    final sub = socket.listen(
      (data) {
        received.addAll(data);
        // ~HS responde 3 bloques STX..ETX.
        if (received.where((b) => b == 0x03).length >= 3) finish();
      },
      onDone: finish,
      onError: (Object _) => finish(),
      cancelOnError: true,
    );
    try {
      socket
        ..add(bytes)
        ..add(ascii.encode('~HS'));
      await socket.flush();
      await answered.future.timeout(_zebraStatusTimeout, onTimeout: () {});
    } finally {
      // Cierre ordenado (FIN) para que la impresora procese todo lo recibido.
      try {
        await socket.close().timeout(const Duration(seconds: 2));
      } on Object {
        // Ya se mandó; el cierre no cambia el resultado.
      }
      socket.destroy();
      await sub.cancel();
    }
    if (received.isEmpty) return const PrintOutcome.sentUnconfirmed();
    final status = ZebraStatus.parse(latin1.decode(received));
    if (status == null) return const PrintOutcome.sentUnconfirmed();
    final problem = status.problemMessage;
    if (problem != null) throw PrinterException(problem);
    return const PrintOutcome.ready();
  }

  /// Nueva config si la impresora (por nombre identificado) apareció en otra
  /// IP de la red; `null` si no hay búsqueda, el nombre es genérico
  /// (`WiFi <ip>`, ingreso manual) o no se encontró una única coincidencia.
  Future<PrinterConfig?> _relocateWifi(PrinterConfig config) async {
    final scanner = _wifiScanner;
    if (scanner == null || config.label.startsWith('WiFi ')) return null;
    final hit = await scanner.findByName(config.label, port: config.wifiPort);
    if (hit == null || hit.host == config.wifiHost) return null;
    // Se conserva el perfil (ZPL/oficina, IPP) de la impresora guardada.
    return config.copyWith(address: hit.address, label: hit.name);
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
  (ref) => LabelPrinter(
    ref.watch(secureStorageProvider),
    wifiScanner: ref.watch(wifiPrinterScannerProvider),
    credentials: ref.watch(printerCredentialsStoreProvider),
    currentUser: () => ref.read(sessionProvider)?.userName,
  ),
);
