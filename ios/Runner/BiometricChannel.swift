import Flutter
import LocalAuthentication

/// Canal nativo de biometría (Face ID / Touch ID / Optic ID) para el ingreso
/// rápido. Contraparte Dart: lib/core/auth/biometric/biometric_authenticator.dart.
///
/// - "capabilities" → {supported, enrolled, types, platformLabel}
/// - "authenticate" {reason, cancel} → "success" | "cancelled" | "lockout" |
///   "notEnrolled" | "notAvailable" | "failed"
enum BiometricChannel {
  private static let channelName = "bo.com.dismac/biometric"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "capabilities":
        result(capabilities())
      case "authenticate":
        let args = call.arguments as? [String: Any]
        authenticate(
          reason: args?["reason"] as? String ?? "",
          cancel: args?["cancel"] as? String ?? "Cancelar",
          result: result
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func capabilities() -> [String: Any] {
    let context = LAContext()
    var error: NSError?
    let canEvaluate = context.canEvaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics, error: &error)
    var supported = canEvaluate
    var enrolled = canEvaluate
    if !canEvaluate, let code = laCode(error) {
      switch code {
      case .biometryNotEnrolled:
        // Hay sensor pero no hay rostro/huella registrado.
        supported = true
        enrolled = false
      case .biometryLockout:
        // Bloqueado por intentos: existe y está registrado; el prompt avisa.
        supported = true
        enrolled = true
      default:
        supported = false
        enrolled = false
      }
    }

    // biometryType se completa después de canEvaluatePolicy.
    var types: [String] = []
    var label: Any = NSNull()
    if context.biometryType == .faceID {
      types.append("face")
      label = "Face ID"
    } else if context.biometryType == .touchID {
      types.append("fingerprint")
      label = "Touch ID"
    } else if #available(iOS 17.0, *), context.biometryType == .opticID {
      types.append("iris")
      label = "Optic ID"
    }

    return [
      "supported": supported,
      "enrolled": enrolled,
      "types": types,
      "platformLabel": label,
    ]
  }

  private static func authenticate(
    reason: String, cancel: String, result: @escaping FlutterResult
  ) {
    let context = LAContext()
    context.localizedCancelTitle = cancel
    // Sin botón "Ingresar contraseña" del sistema: la alternativa es la
    // contraseña de la app, que ya está en la pantalla de login.
    context.localizedFallbackTitle = ""

    var error: NSError?
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    else {
      result(resultCode(for: error))
      return
    }

    context.evaluatePolicy(
      .deviceOwnerAuthenticationWithBiometrics,
      localizedReason: reason.isEmpty ? "Ingresar a DisTrack" : reason
    ) { success, evalError in
      DispatchQueue.main.async {
        result(success ? "success" : resultCode(for: evalError))
      }
    }
  }

  private static func laCode(_ error: Error?) -> LAError.Code? {
    guard let nsError = error as NSError?, nsError.domain == LAErrorDomain else {
      return nil
    }
    return LAError.Code(rawValue: nsError.code)
  }

  private static func resultCode(for error: Error?) -> String {
    guard let code = laCode(error) else { return "failed" }
    switch code {
    case .userCancel, .appCancel, .systemCancel, .userFallback:
      return "cancelled"
    case .biometryLockout:
      return "lockout"
    case .biometryNotEnrolled:
      return "notEnrolled"
    case .biometryNotAvailable, .passcodeNotSet:
      return "notAvailable"
    default:
      return "failed"
    }
  }
}
