/// Momento de la ruta del chofer que se muestra en la notificación en vivo
/// (Android Live Updates / iOS Live Activity + Dynamic Island).
enum RouteLiveState {
  /// Rumbo a la parada en curso.
  onTheWay('on_the_way'),

  /// Dentro de la geocerca de llegada de la parada (≤ 60 m).
  arriving('arriving'),

  /// Lleva un rato quieto dentro de la geocerca: está entregando.
  delivering('delivering'),

  /// No quedan paradas por atender.
  finished('finished');

  const RouteLiveState(this.wireName);

  /// Nombre que viaja por el canal nativo (`status`).
  final String wireName;
}
