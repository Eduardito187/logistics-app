import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../office/label_raster.dart';
import '../office/pdf_image_writer.dart';
import '../office/pwg_raster_writer.dart';
import '../print_outcome.dart';
import '../printer_credentials.dart';
import '../printer_exception.dart';
import 'http_authorization.dart';
import 'ipp_attribute.dart';
import 'ipp_attribute_group.dart';
import 'ipp_codec.dart';
import 'ipp_connection.dart';
import 'ipp_endpoint.dart';
import 'ipp_message.dart';
import 'ipp_operation.dart';
import 'ipp_printer_info.dart';
import 'ipp_status.dart';
import 'ipp_tags.dart';
import 'ipp_transport.dart';

/// Cliente IPP 1.1 (RFC 8011) en Dart puro: ubica la impresora
/// (Get-Printer-Attributes), se autentica si lo pide (HTTP 401 o status
/// not-authenticated/not-authorized → Basic o Digest con las credenciales de
/// la impresora) y manda el trabajo (Print-Job) como PDF o PWG raster.
class IppClient {
  IppClient({
    IppTransport? transport,
    this.timeout = const Duration(seconds: 8),
    this.printTimeout = const Duration(seconds: 60),
    this.httpPorts = const [kIppPort],
    this.httpsPorts = const [443, kIppPort],
    this.paths = const ['/ipp/print', '/ipp', '/printer', '/'],
    this.jobPollInterval = const Duration(seconds: 1),
    this.jobTrackTimeout = const Duration(seconds: 20),
  }) : _transport = transport ?? httpIppTransport;

  /// Cada cuánto se consulta el estado del trabajo tras aceptarlo.
  final Duration jobPollInterval;

  /// Hasta cuándo se sigue el trabajo. Pasado este tiempo sin estado final se
  /// informa "recibido, procesando" (impresoras lentas o colas largas).
  final Duration jobTrackTimeout;

  /// Puerto IPP estándar.
  static const int kIppPort = 631;

  final IppTransport _transport;
  final Duration timeout;
  final Duration printTimeout;
  final List<int> httpPorts;
  final List<int> httpsPorts;
  final List<String> paths;

  int _requestId = 0;

  /// Atributos que se piden a la impresora.
  static const List<String> requestedAttributes = [
    'printer-make-and-model',
    'printer-name',
    'printer-state',
    'printer-state-reasons',
    'printer-is-accepting-jobs',
    'document-format-supported',
    'uri-authentication-supported',
    'uri-security-supported',
    'pwg-raster-document-resolution-supported',
    'pwg-raster-document-type-supported',
  ];

  /// Rutas a probar, en orden: la conocida primero; luego HTTP 631 y, si no
  /// responde, HTTPS (443 y 631) con certificado autofirmado.
  List<IppEndpoint> candidates(
    String host, {
    String? path,
    int? port,
    bool tls = false,
  }) {
    final out = <IppEndpoint>[];
    void add(IppEndpoint e) {
      if (!out.contains(e)) out.add(e);
    }

    if (path != null) {
      add(
        IppEndpoint(host: host, port: port ?? kIppPort, path: path, tls: tls),
      );
    }
    for (final p in httpPorts) {
      for (final route in paths) {
        add(IppEndpoint(host: host, port: p, path: route));
      }
    }
    for (final p in httpsPorts) {
      for (final route in paths) {
        add(IppEndpoint(host: host, port: p, path: route, tls: true));
      }
    }
    return out;
  }

  /// Ubica la impresora IPP en [host] y lee sus atributos.
  ///
  /// Lanza [PrinterException] (con `needsSetup` si faltan/fallan las
  /// credenciales) o [SocketException] si ningún puerto IPP responde (para
  /// que quien llama pueda re-localizar la impresora).
  Future<IppConnection> connect(
    String host, {
    required String userName,
    String? path,
    int? port,
    bool tls = false,
    PrinterCredentials? credentials,
  }) async {
    final deadPorts = <String>{};
    var reachable = false;
    int? lastStatus;
    for (final endpoint in candidates(host, path: path, port: port, tls: tls)) {
      if (deadPorts.contains(endpoint.portKey)) continue;
      try {
        final request = getPrinterAttributesRequest(endpoint, userName);
        final (response, authorization) = await _exchange(
          endpoint,
          IppCodec.encode(request),
          credentials: credentials,
          timeout: timeout,
        );
        reachable = true;
        if (!IppStatus.isSuccess(response.code)) {
          lastStatus = response.code;
          continue;
        }
        return IppConnection(
          endpoint: endpoint,
          info: IppPrinterInfo.fromMessage(response),
          authorization: authorization,
        );
      } on PrinterException {
        rethrow;
      } on FormatException {
        // HTTP 404 / no es IPP en esa ruta: se prueba la siguiente.
        reachable = true;
      } on IOException {
        deadPorts.add(endpoint.portKey);
      } on TimeoutException {
        deadPorts.add(endpoint.portKey);
      }
    }
    if (!reachable) {
      throw const SocketException('La impresora no responde por IPP.');
    }
    final status = lastStatus;
    if (status != null) throw PrinterException(IppStatus.message(status));
    throw const PrinterException(
      'La impresora no responde por IPP. Habilitá IPP en la impresora o '
      'elegí "puerto 9100" en el acceso a la impresora.',
    );
  }

  /// Manda [raster] como trabajo de impresión. PDF si la impresora lo acepta;
  /// si no, PWG raster; si rechaza el formato, prueba el siguiente.
  Future<PrintOutcome> printRaster(
    IppConnection connection,
    LabelRaster raster, {
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) async {
    final info = connection.info;
    final plans = documentPlan(info);
    if (plans.isEmpty) {
      final accepted = info.documentFormats.take(5).join(', ');
      throw PrinterException(
        'La impresora no acepta PDF ni imagen PWG por IPP (acepta: $accepted). '
        'Probá con "puerto 9100" en el acceso a la impresora.',
      );
    }
    for (var i = 0; i < plans.length; i++) {
      final mime = plans[i];
      final data = buildDocument(mime, raster, info);
      final request = printJobRequest(
        connection.endpoint,
        userName: userName,
        jobName: jobName,
        documentFormat: mime,
        data: data,
      );
      final (response, _) = await _exchange(
        connection.endpoint,
        IppCodec.encode(request),
        credentials: credentials,
        cached: connection.authorization,
        timeout: printTimeout,
      );
      if (IppStatus.isSuccess(response.code)) {
        final jobState = response.attribute('job-state')?.integer;
        // 7 = cancelado, 8 = abortado: la impresora lo descartó.
        if (jobState == 7 || jobState == 8) {
          throw PrinterException(
            canceledMessage(
              response.attribute('job-state-reasons')?.strings ?? const [],
              info,
            ),
            cancelledAtDevice: true,
          );
        }
        final jobId = response.attribute('job-id')?.integer;
        // "Aceptado" NO es "impreso": una impresora con autenticación de
        // usuarios (Ricoh/Windows) acepta el Print-Job y lo cancela un instante
        // después (`job-canceled-at-device`). Se sigue el trabajo hasta su
        // estado final para no mostrar un éxito falso.
        if (jobId == null) {
          return PrintOutcome.accepted(note: info.problem);
        }
        return trackJob(
          connection,
          jobId,
          userName: userName,
          credentials: credentials,
        );
      }
      final isLast = i == plans.length - 1;
      if (response.code ==
              IppStatus.clientErrorDocumentFormatNotSupported &&
          !isLast) {
        continue;
      }
      throw PrinterException(_statusText(response));
    }
    throw const PrinterException('La impresora rechazó el trabajo.');
  }

  /// Sigue el trabajo [jobId] con Get-Job-Attributes hasta un estado final:
  /// 9 completado → impreso; 7/8 cancelado/abortado → [PrinterException] con
  /// el motivo; 4 retenido → retenido (liberar en el panel). Si la impresora
  /// no responde a la consulta, o no termina a tiempo → "recibido".
  Future<PrintOutcome> trackJob(
    IppConnection connection,
    int jobId, {
    required String userName,
    PrinterCredentials? credentials,
  }) async {
    final info = connection.info;
    final deadline = DateTime.now().add(jobTrackTimeout);
    while (true) {
      await Future<void>.delayed(jobPollInterval);
      final IppMessage response;
      try {
        (response, _) = await _exchange(
          connection.endpoint,
          IppCodec.encode(
            getJobAttributesRequest(connection.endpoint, userName, jobId),
          ),
          credentials: credentials,
          cached: connection.authorization,
          timeout: timeout,
        );
      } on Object catch (e) {
        // Sin seguimiento posible (red, impresora que no lo soporta): no se
        // inventa un resultado, se informa lo único seguro.
        debugPrint('IPP: no se pudo seguir el trabajo #$jobId: $e');
        return PrintOutcome.accepted(jobId: jobId, note: info.problem);
      }
      if (!IppStatus.isSuccess(response.code)) {
        debugPrint(
          'IPP: Get-Job-Attributes #$jobId → status 0x'
          '${response.code.toRadixString(16)}',
        );
        return PrintOutcome.accepted(jobId: jobId, note: info.problem);
      }
      final state = response.attribute('job-state')?.integer;
      final reasons =
          response.attribute('job-state-reasons')?.strings ?? const [];
      switch (state) {
        case 9:
          return PrintOutcome.printed(jobId: jobId);
        case 7:
        case 8:
          throw PrinterException(
            canceledMessage(reasons, info),
            cancelledAtDevice: true,
          );
        case 4:
          return PrintOutcome.held(jobId: jobId);
      }
      if (DateTime.now().isAfter(deadline)) {
        return PrintOutcome.accepted(jobId: jobId, note: info.problem);
      }
    }
  }

  /// Texto de un trabajo cancelado/abortado según sus `job-state-reasons`.
  static String canceledMessage(List<String> reasons, IppPrinterInfo info) {
    bool has(String r) => reasons.any((x) => x.startsWith(r));
    if (has('job-canceled-at-device') ||
        has('job-canceled-by-system') ||
        has('account-') ||
        has('job-authorization')) {
      // Caso real (Ricoh IM 550, nov 2026): IPP solo admite el nombre de
      // usuario y la impresora exige autenticación → cancela todo trabajo.
      final userOnly = info.wantsUserName && !info.requiresCredentials;
      return userOnly
          ? 'La impresora canceló el trabajo: exige iniciar sesión para '
                'imprimir y por IPP solo acepta el nombre de usuario, sin '
                'contraseña. Sistemas debe habilitar la "Autenticación IPP" '
                '(Basic/Digest) o permitir imprimir sin autenticación desde '
                'la red WiFi. Detalle en Ajustes → Impresora → Acceso.'
          : 'La impresora canceló el trabajo: no aceptó tu usuario o '
                'contraseña de dominio. Revisalos en el acceso a la impresora.';
    }
    if (has('document-format-error') || has('document-unprintable')) {
      return 'La impresora no pudo procesar el documento. Probá con '
          '"puerto 9100" en el acceso a la impresora.';
    }
    if (has('job-canceled-by-user')) {
      return 'El trabajo se canceló desde la impresora.';
    }
    final detail = reasons.isEmpty ? '' : ' (${reasons.join(', ')})';
    return 'La impresora canceló el trabajo$detail.';
  }

  /// Pedido Get-Job-Attributes del trabajo [jobId].
  IppMessage getJobAttributesRequest(
    IppEndpoint endpoint,
    String userName,
    int jobId,
  ) {
    return IppMessage(
      code: IppOperation.getJobAttributes,
      requestId: ++_requestId,
      groups: [
        IppAttributeGroup(IppTag.operationAttributes, [
          ..._baseOperation(endpoint, userName),
          IppAttribute('job-id', IppTag.integer, [jobId]),
          IppAttribute('requested-attributes', IppTag.keyword, const [
            'job-state',
            'job-state-reasons',
            'job-impressions-completed',
          ]),
        ]),
      ],
    );
  }

  /// Formatos a intentar, en orden de preferencia.
  static List<String> documentPlan(IppPrinterInfo info) {
    if (info.documentFormats.isEmpty) return const ['application/pdf'];
    return [
      if (info.supports('application/pdf')) 'application/pdf',
      if (info.supports('image/pwg-raster')) 'image/pwg-raster',
      // "Autodetectar": casi todas reconocen el PDF solas.
      if (!info.supports('application/pdf') &&
          info.supports('application/octet-stream'))
        'application/octet-stream',
    ];
  }

  /// Bytes del documento para [mime].
  static Uint8List buildDocument(
    String mime,
    LabelRaster raster,
    IppPrinterInfo info,
  ) {
    if (mime == 'image/pwg-raster') {
      return PwgRasterWriter.build(
        raster,
        dpi: pwgResolution(info),
        rgb:
            info.pwgTypes.isNotEmpty &&
            !info.pwgTypes.contains('sgray_8') &&
            info.pwgTypes.contains('srgb_8'),
      );
    }
    return PdfImageWriter.build(raster);
  }

  /// Resolución PWG: 300 si la acepta; si no, la menor ≥150; por defecto 300.
  static int pwgResolution(IppPrinterInfo info) {
    final dpis = info.pwgResolutions.map((r) => r.dpiX).toList()..sort();
    if (dpis.isEmpty || dpis.contains(300)) return 300;
    return dpis.firstWhere((d) => d >= 150, orElse: () => dpis.first);
  }

  /// Pedido Get-Printer-Attributes.
  IppMessage getPrinterAttributesRequest(
    IppEndpoint endpoint,
    String userName,
  ) {
    return IppMessage(
      code: IppOperation.getPrinterAttributes,
      requestId: ++_requestId,
      groups: [
        IppAttributeGroup(IppTag.operationAttributes, [
          ..._baseOperation(endpoint, userName),
          IppAttribute(
            'requested-attributes',
            IppTag.keyword,
            requestedAttributes,
          ),
        ]),
      ],
    );
  }

  /// Pedido Print-Job con el documento.
  IppMessage printJobRequest(
    IppEndpoint endpoint, {
    required String userName,
    required String jobName,
    required String documentFormat,
    required Uint8List data,
  }) {
    return IppMessage(
      code: IppOperation.printJob,
      requestId: ++_requestId,
      groups: [
        IppAttributeGroup(IppTag.operationAttributes, [
          ..._baseOperation(endpoint, userName),
          IppAttribute('job-name', IppTag.nameWithoutLanguage, [jobName]),
          IppAttribute('document-format', IppTag.mimeMediaType, [
            documentFormat,
          ]),
        ]),
      ],
      data: data,
    );
  }

  List<IppAttribute> _baseOperation(IppEndpoint endpoint, String userName) => [
    IppAttribute('attributes-charset', IppTag.charset, const ['utf-8']),
    IppAttribute('attributes-natural-language', IppTag.naturalLanguage, const [
      'es',
    ]),
    IppAttribute('printer-uri', IppTag.uri, [endpoint.printerUri]),
    IppAttribute('requesting-user-name', IppTag.nameWithoutLanguage, [
      userName.trim().isEmpty ? 'distrack' : userName.trim(),
    ]),
  ];

  /// POST con autenticación. Devuelve la respuesta IPP y la cabecera
  /// `Authorization` que funcionó (o `null`).
  ///
  /// - HTTP 401: con contraseña → reintenta con Basic/Digest según el
  ///   desafío; sin ella → error claro pidiendo el usuario de dominio.
  /// - Status 0x0402/0x0403 sin haber mandado credenciales → reintenta Basic.
  /// - Cualquier otro HTTP que no sea 200 o un cuerpo que no es IPP →
  ///   [FormatException] (ruta equivocada).
  Future<(IppMessage, String?)> _exchange(
    IppEndpoint endpoint,
    Uint8List body, {
    required Duration timeout,
    PrinterCredentials? credentials,
    String? cached,
  }) async {
    var authorization = cached;
    var response = await _transport(
      endpoint.httpUri,
      body,
      authorization: authorization,
      timeout: timeout,
    );
    if (response.statusCode == 401) {
      final creds = _requirePassword(credentials);
      authorization = HttpAuthorization.forChallenges(
        response.challenges,
        method: 'POST',
        path: endpoint.path,
        user: creds.authUser,
        password: creds.password!,
      );
      response = await _transport(
        endpoint.httpUri,
        body,
        authorization: authorization,
        timeout: timeout,
      );
      if (response.statusCode == 401) throw _rejected(creds);
    }
    if (response.statusCode != 200) {
      throw FormatException('HTTP ${response.statusCode}');
    }
    var message = IppCodec.decode(response.body);
    if (IppStatus.isAuthProblem(message.code)) {
      final creds = credentials;
      if (authorization == null && creds != null && creds.hasPassword) {
        authorization = HttpAuthorization.basic(
          creds.authUser,
          creds.password!,
        );
        response = await _transport(
          endpoint.httpUri,
          body,
          authorization: authorization,
          timeout: timeout,
        );
        if (response.statusCode == 401) throw _rejected(creds);
        if (response.statusCode != 200) {
          throw FormatException('HTTP ${response.statusCode}');
        }
        message = IppCodec.decode(response.body);
      }
      if (IppStatus.isAuthProblem(message.code)) {
        if (creds == null || !creds.hasPassword) {
          _requirePassword(creds);
        }
        if (message.code == IppStatus.clientErrorNotAuthorized) {
          throw PrinterException(
            'La impresora no autoriza al usuario «${creds!.authUser}» a '
            'imprimir. Pedí a sistemas que lo habilite.',
            needsSetup: true,
          );
        }
        throw _rejected(creds!);
      }
    }
    return (message, authorization);
  }

  /// Credenciales con contraseña, o error pidiendo cargarlas.
  PrinterCredentials _requirePassword(PrinterCredentials? credentials) {
    if (credentials == null || credentials.username.trim().isEmpty) {
      throw const PrinterException(
        'La impresora pide usuario y contraseña (como en la PC). Ingresá tu '
        'usuario de dominio en Ajustes › Impresora › Acceso a la impresora.',
        needsSetup: true,
      );
    }
    if (!credentials.hasPassword) {
      throw PrinterException(
        'La impresora pide la contraseña de «${credentials.authUser}». '
        'Ingresala en Ajustes › Impresora › Acceso a la impresora.',
        needsSetup: true,
      );
    }
    return credentials;
  }

  PrinterException _rejected(PrinterCredentials creds) => PrinterException(
    'La impresora rechazó el usuario «${creds.authUser}» o la contraseña. '
    'Revisalos en Ajustes › Impresora › Acceso a la impresora.',
    needsSetup: true,
  );

  /// Mensaje del status + `status-message` de la impresora si vino.
  static String _statusText(IppMessage response) {
    final base = IppStatus.message(response.code);
    final detail = response.attribute('status-message')?.string?.trim();
    return detail == null || detail.isEmpty ? base : '$base ($detail)';
  }
}
