/// Etiquetas (tags) de la codificación binaria IPP (RFC 8010 §3.5).
abstract final class IppTag {
  // --- Delimitadores de grupo -------------------------------------------
  static const int operationAttributes = 0x01;
  static const int jobAttributes = 0x02;
  static const int endOfAttributes = 0x03;
  static const int printerAttributes = 0x04;
  static const int unsupportedAttributes = 0x05;

  // --- Valores "fuera de banda" ------------------------------------------
  static const int unsupported = 0x10;
  static const int unknown = 0x12;
  static const int noValue = 0x13;

  // --- Enteros -------------------------------------------------------------
  static const int integer = 0x21;
  static const int boolean = 0x22;
  static const int enumeration = 0x23;

  // --- Octetos -------------------------------------------------------------
  static const int octetString = 0x30;
  static const int dateTime = 0x31;
  static const int resolution = 0x32;
  static const int rangeOfInteger = 0x33;
  static const int begCollection = 0x34;
  static const int textWithLanguage = 0x35;
  static const int nameWithLanguage = 0x36;
  static const int endCollection = 0x37;

  // --- Cadenas -------------------------------------------------------------
  static const int textWithoutLanguage = 0x41;
  static const int nameWithoutLanguage = 0x42;
  static const int keyword = 0x44;
  static const int uri = 0x45;
  static const int uriScheme = 0x46;
  static const int charset = 0x47;
  static const int naturalLanguage = 0x48;
  static const int mimeMediaType = 0x49;
  static const int memberAttrName = 0x4A;

  /// Tag extendido: los 4 bytes siguientes son el tag real.
  static const int extension = 0x7F;

  /// `true` si [tag] delimita un grupo (o el fin de atributos).
  static bool isDelimiter(int tag) => tag >= 0x00 && tag <= 0x0F;

  /// `true` si el valor de [tag] es texto (se decodifica como UTF-8).
  static bool isString(int tag) => tag >= 0x40 && tag <= 0x5F;
}
