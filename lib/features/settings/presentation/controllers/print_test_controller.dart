import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session.dart';
import '../../../../core/printing/label_printer.dart';
import '../../../../core/printing/printer_exception.dart';
import '../../../../core/printing/render/test_page_renderer.dart';
import '../../../../core/widgets/app_snack.dart';
import 'print_result_message.dart';
import 'print_test_state.dart';
import 'settings_controllers.dart';

/// ZPL mínimo para verificar que la impresora responde.
const String kTestZpl = '^XA^FO40,40^A0N,40,40^FDPrueba DisTrack^FS^XZ';

/// Impresión de prueba compartida entre la tarjeta "Impresora" de Ajustes y
/// el asistente "Conectar impresora" (los dos muestran el mismo resultado).
///
/// El resultado es veraz: "impreso" / "retenido" / "recibió" solo si la
/// impresora lo confirmó (`PrintOutcome`), "no confirma" por 9100 y el motivo
/// real si falló.
class PrintTestController extends Notifier<PrintTestState> {
  @override
  PrintTestState build() => const PrintTestState();

  /// Imprime la prueba en la impresora activa. `null` si ya había una en
  /// curso.
  Future<PrintResultMessage?> run() async {
    if (state.printing) return null;
    state = PrintTestState(printing: true, lastResult: state.lastResult);
    final deviceName = _deviceName();
    PrintResultMessage message;
    try {
      final outcome = await ref
          .read(labelPrinterProvider)
          .printLabel(
            zpl: kTestZpl,
            // Impresoras de oficina: hoja simple dibujada (no entienden ZPL).
            render: () => renderTestPage(deviceName: deviceName),
            jobName: 'Prueba DisTrack',
          );
      final text = outcome.kind == PrintOutcomeKind.sent
          ? 'Etiqueta de prueba enviada.'
          : outcome.message;
      message = PrintResultMessage(
        text,
        tone: outcome.kind == PrintOutcomeKind.sentUnconfirmed
            ? PrintResultTone.unconfirmed
            : PrintResultTone.ok,
      );
    } on PrinterException catch (e) {
      // Mensaje en español listo para el operario: se muestra tal cual.
      message = PrintResultMessage(e.message, tone: PrintResultTone.error);
    }
    if (ref.mounted) {
      state = PrintTestState(lastResult: message);
    }
    return message;
  }

  /// Borra el resultado anterior (al cambiar de impresora).
  void clear() {
    if (state.lastResult != null) {
      state = PrintTestState(printing: state.printing);
    }
  }

  /// Nombre del teléfono para la hoja de prueba de oficina.
  String _deviceName() {
    final os = Platform.isIOS ? 'iPhone' : 'Android';
    try {
      final name = ref.read(appMeProvider).value?.device?.name?.trim();
      if (name != null && name.isNotEmpty) return name;
      final user = ref.read(sessionProvider)?.userName;
      return user == null ? 'Teléfono $os' : 'Teléfono $os de $user';
    } on Object {
      return 'Teléfono $os';
    }
  }
}

final printTestControllerProvider =
    NotifierProvider.autoDispose<PrintTestController, PrintTestState>(
      PrintTestController.new,
    );

/// Imprime la prueba y avisa el resultado con un aviso breve (además del
/// resultado fijo que dibuja `PrintResultText`).
Future<void> runPrintTest(BuildContext context, WidgetRef ref) async {
  final message = await ref.read(printTestControllerProvider.notifier).run();
  if (message == null || !context.mounted) return;
  switch (message.tone) {
    case PrintResultTone.ok:
      showSuccessSnack(context, message.text);
    case PrintResultTone.unconfirmed || PrintResultTone.error:
      showInfoSnack(context, message.text);
  }
}
