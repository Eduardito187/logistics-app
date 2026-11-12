/// Operaciones IPP que usa la app (RFC 8011 §5.4.15).
abstract final class IppOperation {
  static const int printJob = 0x0002;
  static const int validateJob = 0x0004;
  static const int getJobAttributes = 0x0009;
  static const int getPrinterAttributes = 0x000B;
}
