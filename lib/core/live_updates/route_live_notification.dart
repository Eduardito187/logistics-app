/// Identidad de la notificación ÚNICA del chofer en Android.
///
/// La ruta en vivo (`LiveUpdatesChannel.kt`, `NOTIFICATION_ID = 4120`) y el
/// foreground service del rastreo (`TruckTrackingService`, `serviceId`) usan
/// el MISMO id: Android exige una notificación mientras corre el servicio, y
/// al publicar la ruta con ese id el sistema le re-aplica la marca de
/// foreground service. Resultado: una sola notificación ("Parada 1 de 7 ·
/// Llega 08:15") en vez de dos.
///
/// Archivo SIN dependencias a propósito: lo importa `lib/core/location/` sin
/// crear un ciclo con `lib/core/live_updates/` (que ya depende del rastreo).
library;

/// Id de la notificación de ruta en vivo = id del foreground service.
/// Debe coincidir con `LiveUpdatesChannel.NOTIFICATION_ID` (Kotlin).
const int routeLiveNotificationId = 4120;

/// Título que pone el plugin del foreground service al arrancar, antes de que
/// la ruta en vivo publique su contenido encima (o si el sistema reinicia el
/// servicio sin la app). Neutro: no revela el rastreo de ubicación.
const String routeLiveFallbackTitle = 'DisTrack';

/// Texto neutro del foreground service sin contenido de ruta.
const String routeLiveFallbackText = 'En servicio';
