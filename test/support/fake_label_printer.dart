import 'dart:async';

import 'package:logistics_app/core/printing/label_printer.dart';
import 'package:logistics_app/core/printing/printer_config.dart';

/// Impresora falsa para Ajustes y el asistente "Conectar impresora": registra
/// lo guardado y lo impreso, sin hardware ni red.
class FakeLabelPrinter implements LabelPrinter {
  FakeLabelPrinter({
    this.failOnSelect = false,
    this.outcome = const PrintOutcome.sent(),
    this.printError,
  });

  /// Si es true, guardar lanza (almacén seguro roto).
  final bool failOnSelect;

  /// Resultado de cada impresión (si no hay [printError]).
  final PrintOutcome outcome;
  final PrinterException? printError;

  /// Si no es null, cada impresión espera a que se complete (para ver el
  /// estado "imprimiendo").
  Completer<void>? hold;

  final List<PrinterConfig> selections = [];
  int prints = 0;
  String? lastZpl;
  String? lastJobName;

  @override
  Future<List<PrinterDevice>> discover(PrinterTransport transport) async =>
      const [];

  @override
  Future<PrinterConfig?> selectedPrinter() async => null;

  @override
  Future<void> selectPrinter(PrinterConfig config) async {
    if (failOnSelect) throw Exception('almacén roto');
    selections.add(config);
  }

  @override
  Future<void> printZpl(String zpl, {PrinterConfig? to}) async {
    await printLabel(zpl: zpl, to: to);
  }

  @override
  Future<PrintOutcome> printLabel({
    required String zpl,
    LabelRenderer? render,
    String? jobName,
    PrinterConfig? to,
  }) async {
    prints++;
    lastZpl = zpl;
    lastJobName = jobName;
    final wait = hold;
    if (wait != null) await wait.future;
    final error = printError;
    if (error != null) throw error;
    return outcome;
  }
}
