# Reglas R8 de la app (release con isMinifyEnabled + isShrinkResources).
#
# El plugin de Flutter ya agrega `proguard-android-optimize.txt` y sus propias
# reglas del embedding. Varios plugins traen reglas "consumer" (mobile_scanner /
# ML Kit, Firebase). Acá va solo lo que falta. Ver docs/rendimiento-y-pantallas.md.

# --- Flutter: deferred components referencian Play Core, que no usamos. ---
-dontwarn com.google.android.play.core.**

# --- flutter_local_notifications: guarda las notificaciones programadas con
# Gson (reflexión sobre sus modelos). Sin esto R8 renombra campos y se rompen
# al deserializar.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# --- firebase_messaging: el servicio y el receiver se declaran en el manifest
# del plugin (R8 los conserva); se mantiene el plugin por el handler en
# segundo plano que se registra por reflexión.
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# --- flutter_foreground_task: servicio de GPS en primer plano; el task
# handler se reinstancia desde el servicio.
-keep class com.pravera.flutter_foreground_task.** { *; }

# --- flutter_blue_plus: impresión ZPL por Bluetooth (Zebra ZQ630).
-keep class com.lib.flutter_blue_plus.** { *; }

# --- usb_serial (copia en third_party/) + librería felHR85 UsbSerial: los
# drivers de chips USB-serie se eligen por reflexión según el VID/PID.
-keep class dev.bessems.usbserial.** { *; }
-keep class com.felhr.** { *; }
-dontwarn com.felhr.**

# --- mobile_scanner / ML Kit: trae sus reglas consumer; esto cubre las clases
# nativas del detector que se cargan por JNI.
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# --- drift / sqlite3: la base es nativa (FFI desde Dart), sin clases Java que
# conservar más allá del plugin de librerías nativas.
-keep class eu.simonbinder.sqlite3_flutter_libs.** { *; }
