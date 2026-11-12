/// Nombre/modelo de una impresora de red, leído de su página web interna.
///
/// Se identifica por HTTP (puerto 80/443) y NUNCA mandando comandos al puerto
/// 9100: cualquier byte que llegue ahí a una impresora que no sea Zebra (una
/// láser de oficina, por ejemplo) se imprime como basura en papel.
class NetworkPrinterIdentity {
  const NetworkPrinterIdentity({required this.name, required this.isZebra});

  final String name;
  final bool isZebra;

  /// Patrón de modelos Zebra (ZD421, ZT230, ZQ630, GK420…) o la marca.
  static final RegExp _zebraPattern = RegExp(
    r'zebra|\bz[tdqc]\d{3}|\bgk4\d{2}|\bgx4\d{2}|\bzm4\d{2}|\bztc\b',
    caseSensitive: false,
  );

  /// `true` si [text] (nombre de servicio, modelo, título) es de una Zebra.
  static bool looksLikeZebra(String text) => _zebraPattern.hasMatch(text);

  /// `true` si [text] es de una Ricoh (o sus marcas: Savin, Lanier, Gestetner,
  /// NRG, Nashuatec). Esas MFP suelen tener autenticación de usuario que por
  /// IPP cancela el trabajo; se imprime por 9100 con el código de usuario.
  static bool looksLikeRicoh(String text) => _ricohPattern.hasMatch(text);

  static final RegExp _ricohPattern = RegExp(
    r'ricoh|savin|lanier|gestetner|nashuatec|\bnrg\b|\bim\s?\d{3,4}\b|\bmp\s?c?\d{3,4}\b|aficio',
    caseSensitive: false,
  );

  static final RegExp _titlePattern = RegExp(
    r'<title[^>]*>([\s\S]*?)</title>',
    caseSensitive: false,
  );

  /// Extrae la identidad de la respuesta HTTP cruda (cabeceras + HTML).
  /// `null` si no hay un `<title>` útil y tampoco se reconoce una Zebra.
  static NetworkPrinterIdentity? fromHttpResponse(String raw) {
    final isZebra = _zebraPattern.hasMatch(raw);
    final match = _titlePattern.firstMatch(raw);
    final title = match == null ? '' : _clean(match.group(1)!);
    if (title.isEmpty) {
      return isZebra
          ? const NetworkPrinterIdentity(name: 'Zebra', isZebra: true)
          : null;
    }
    return NetworkPrinterIdentity(name: title, isZebra: isZebra);
  }

  static String _clean(String s) {
    final text = s
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Un título muy largo no sirve como nombre en la UI.
    return text.length > 60 ? '${text.substring(0, 60)}…' : text;
  }
}
