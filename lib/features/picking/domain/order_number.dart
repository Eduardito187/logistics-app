/// Reglas del número de pedido en preparación.
///
/// Un número de pedido es corto y alfanumérico (`DIS-123456`, `100045`). Todo
/// lo demás (el JSON firmado de una etiqueta QR, URLs, textos con espacios) NO
/// es un pedido: antes se usaba tal cual y el header mostraba
/// `Pedido {"v":1,"t":"PKG",…}` con "el pedido no tiene productos".
library;

final RegExp _orderNumberPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{1,39}$');

/// `true` si [value] tiene forma de número de pedido.
bool isPlausibleOrderNumber(String value) =>
    _orderNumberPattern.hasMatch(value.trim());

/// Ruta de la pantalla de preparación del pedido [orderNumber] (codificado
/// para que nunca rompa la ruta).
String orderPreparationPath(String orderNumber) =>
    '/picking/order/${Uri.encodeComponent(orderNumber.trim())}';
