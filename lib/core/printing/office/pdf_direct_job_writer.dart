import 'dart:typed_data';

import '../printer_credentials.dart';
import 'label_raster.dart';
import 'office_pjl.dart';
import 'pdf_image_writer.dart';

/// Trabajo de **PDF directo** para el puerto 9100: cabecera PJL (código de
/// usuario Ricoh) + `@PJL ENTER LANGUAGE=PDF` + el PDF de la etiqueta.
///
/// Es la vía que la Ricoh IM 550 imprime bien por 9100 (verificado en equipo):
/// el PCL5 crudo le salía en blanco; el PDF sale con su contenido. Las MFP de
/// oficina modernas (Ricoh, HP, Xerox, Canon) soportan "PDF Direct Print".
abstract final class PdfDirectJobWriter {
  static Uint8List build(
    LabelRaster raster, {
    required String jobName,
    required String userName,
    PrinterCredentials? credentials,
  }) {
    final out = BytesBuilder(copy: false);
    out.add(
      OfficePjl.header(
        language: 'PDF',
        jobName: jobName,
        userName: userName,
        credentials: credentials,
      ),
    );
    out.add(PdfImageWriter.build(raster));
    out.add(OfficePjl.footer(jobName));
    return out.takeBytes();
  }
}
