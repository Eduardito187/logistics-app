/// Estado que pinta el widget nativo (campo `state` de todo payload).
enum HomeWidgetState {
  /// Con datos.
  ok('ok'),

  /// Sin sesión: el widget invita a iniciar sesión.
  signedOut('signedOut'),

  /// El widget no corresponde al rol del usuario logueado.
  notAllowed('notAllowed'),

  /// Con sesión pero sin nada que mostrar (sin ruta, ruta terminada, sin
  /// pedidos, o datos todavía no cargados).
  empty('empty');

  const HomeWidgetState(this.wireName);

  /// Valor del canal nativo.
  final String wireName;
}
