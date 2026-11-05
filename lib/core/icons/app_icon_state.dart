/// Estado "en acción" de un [AnimatedAppIcon]. Cada cambio de estado dispara
/// su animación (ver docs/custom-animated-icons-brief.md §5):
///
/// - [idle]: quieto (solo el botón central "respira" si se pide `ambient`).
/// - [active]: seleccionado/activo. Al entrar se dibuja y rellena (200–500 ms)
///   y queda relleno mientras siga activo.
/// - [pressed]: dedo apoyado. Escala 0.9 + opacidad 0.9 (80 ms). Además, todo
///   ícono reacciona solo al toque sobre él, sin que el llamador lo pida.
/// - [loading]: loop sutil mientras corre una acción (escaneo, sync, impresión,
///   GPS). Se corta al instante cuando cambia el estado.
/// - [success]: trazo que se dibuja + pop 1.0→1.15→1.0, una sola vez.
/// - [error]: sacudida horizontal corta + pulso ámbar, una sola vez.
enum AppIconState { idle, active, pressed, loading, success, error }
