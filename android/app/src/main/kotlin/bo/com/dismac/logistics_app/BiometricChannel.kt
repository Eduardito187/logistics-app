package bo.com.dismac.logistics_app

import android.content.pm.PackageManager
import android.os.Build
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_STRONG
import androidx.biometric.BiometricManager.Authenticators.BIOMETRIC_WEAK
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Canal nativo de biometría (huella / rostro / iris) para el ingreso rápido.
 * Contraparte Dart: lib/core/auth/biometric/biometric_authenticator.dart.
 *
 * - "capabilities" → {supported, enrolled, types, platformLabel}
 * - "authenticate" {reason, cancel} → "success" | "cancelled" | "lockout" |
 *   "notEnrolled" | "notAvailable" | "failed"
 */
object BiometricChannel {
    private const val CHANNEL = "bo.com.dismac/biometric"

    // Clase 3 (fuerte) o clase 2 (débil): muchos teléfonos de gama media solo
    // tienen rostro clase 2. La credencial vive en el almacén seguro, no se
    // ata a una clave criptográfica, así que alcanza con confirmar presencia.
    private const val AUTHENTICATORS = BIOMETRIC_STRONG or BIOMETRIC_WEAK

    fun register(engine: FlutterEngine, activity: FragmentActivity) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "capabilities" -> result.success(capabilities(activity))
                    "authenticate" -> authenticate(
                        activity,
                        reason = call.argument<String>("reason") ?: "",
                        cancel = call.argument<String>("cancel") ?: "Cancelar",
                        result = result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun capabilities(activity: FragmentActivity): Map<String, Any?> {
        val status = BiometricManager.from(activity).canAuthenticate(AUTHENTICATORS)
        val (supported, enrolled) = when (status) {
            BiometricManager.BIOMETRIC_SUCCESS -> true to true
            // Hay sensor pero ninguna huella/rostro registrado.
            BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> true to false
            // Sin hardware, sensor no disponible, actualización de seguridad
            // pendiente o estado desconocido: no se ofrece.
            else -> false to false
        }
        return mapOf(
            "supported" to supported,
            "enrolled" to enrolled,
            "types" to types(activity),
            "platformLabel" to null,
        )
    }

    /** Tipos de sensor que el teléfono declara tener (lo que realmente hay). */
    private fun types(activity: FragmentActivity): List<String> {
        val pm = activity.packageManager
        val types = mutableListOf<String>()
        if (pm.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)) types.add("fingerprint")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (pm.hasSystemFeature(PackageManager.FEATURE_FACE)) types.add("face")
            if (pm.hasSystemFeature(PackageManager.FEATURE_IRIS)) types.add("iris")
        }
        return types
    }

    private fun authenticate(
        activity: FragmentActivity,
        reason: String,
        cancel: String,
        result: MethodChannel.Result,
    ) {
        activity.runOnUiThread {
            // Se responde UNA sola vez: el callback puede emitir más de un
            // evento (p. ej. error tras cancelar) y un segundo success() crashea.
            var replied = false
            fun reply(value: String) {
                if (replied) return
                replied = true
                result.success(value)
            }

            when (BiometricManager.from(activity).canAuthenticate(AUTHENTICATORS)) {
                BiometricManager.BIOMETRIC_SUCCESS -> Unit
                BiometricManager.BIOMETRIC_ERROR_NONE_ENROLLED -> {
                    reply("notEnrolled")
                    return@runOnUiThread
                }
                else -> {
                    reply("notAvailable")
                    return@runOnUiThread
                }
            }

            if (activity.isFinishing || activity.isDestroyed) {
                reply("notAvailable")
                return@runOnUiThread
            }

            val callback = object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    authResult: BiometricPrompt.AuthenticationResult,
                ) = reply("success")

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) =
                    reply(mapError(errorCode))

                // Un dedo/rostro no reconocido NO termina: el prompt sigue
                // abierto y el sistema decide cuándo bloquear (lockout).
                override fun onAuthenticationFailed() = Unit
            }

            val info = BiometricPrompt.PromptInfo.Builder()
                .setTitle("DisTrack")
                .setSubtitle(reason)
                .setNegativeButtonText(cancel)
                .setAllowedAuthenticators(AUTHENTICATORS)
                // Rostro pasivo: entra sin tocar "Confirmar".
                .setConfirmationRequired(false)
                .build()

            try {
                BiometricPrompt(activity, ContextCompat.getMainExecutor(activity), callback)
                    .authenticate(info)
            } catch (e: Exception) {
                reply("notAvailable")
            }
        }
    }

    private fun mapError(code: Int): String = when (code) {
        BiometricPrompt.ERROR_USER_CANCELED,
        BiometricPrompt.ERROR_NEGATIVE_BUTTON,
        BiometricPrompt.ERROR_CANCELED -> "cancelled"
        BiometricPrompt.ERROR_LOCKOUT,
        BiometricPrompt.ERROR_LOCKOUT_PERMANENT -> "lockout"
        BiometricPrompt.ERROR_NO_BIOMETRICS -> "notEnrolled"
        BiometricPrompt.ERROR_HW_NOT_PRESENT,
        BiometricPrompt.ERROR_HW_UNAVAILABLE -> "notAvailable"
        else -> "failed"
    }
}
