import '../api/models/accepted_envelope.dart';
import 'command_status.dart';

// Se reexporta [CommandStatus] (movido a su propio archivo por SRP) para no
// romper a quienes importan `commands/command_outcome.dart`.
export 'command_status.dart';

/// Resultado de un comando de escritura contra el backend.
///
/// Sirve para que la presentación trate distinto los comandos **directos**
/// (síncronos, [CommandOutcome.applied]) de los **asíncronos** que responden
/// 202 ([CommandOutcome.accepted]). Nunca hay que dar por aplicado un 202: tras
/// un [accepted] conviene invalidar las lecturas para que se refresquen cuando
/// el backend procese la orden.
class CommandOutcome {
  /// Comando síncrono: el backend ya aplicó el cambio.
  const CommandOutcome.applied({this.message}) : status = CommandStatus.applied;

  /// Comando asíncrono: el backend aceptó la orden y la procesa después.
  const CommandOutcome.accepted({this.message})
    : status = CommandStatus.accepted;

  /// Construye el resultado asíncrono a partir de la respuesta 202 del backend.
  ///
  /// `AcceptedEnvelope.data.accepted` sólo confirma que el backend tomó la
  /// orden; el envelope no trae un texto propio para mostrar, así que la UI usa
  /// su copy por defecto. Si en el futuro el envelope sumara un mensaje, se
  /// pasa acá y la UI lo prioriza.
  factory CommandOutcome.fromAccepted(AcceptedEnvelope envelope) {
    assert(envelope.data.accepted, 'El backend respondió 202 sin aceptar.');
    return const CommandOutcome.accepted();
  }

  final CommandStatus status;

  /// Mensaje que trae el backend, si lo hubiera. Puede ser null; en ese caso la
  /// UI usa el texto por defecto según el [status].
  final String? message;

  /// true si el backend aún está procesando la orden (202 async).
  bool get isAccepted => status == CommandStatus.accepted;

  /// true si el cambio ya quedó aplicado (respuesta directa).
  bool get isApplied => status == CommandStatus.applied;
}
