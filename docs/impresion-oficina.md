# Impresión en impresoras de oficina (Ricoh, HP…) y Zebra por WiFi

Nov 2026. Caso real: **Ricoh IM 550 PCL 6** (láser de oficina) en `192.168.2.154:9100`, con autenticación
de usuario (Windows/LDAP o código de usuario). La app decía "Etiqueta enviada" pero no salía nada.

## Por qué fallaba

1. La app mandaba **ZPL crudo** (lenguaje de Zebra) por el puerto 9100. Una láser no entiende ZPL: lo
   imprime como texto o lo descarta.
2. El puerto 9100 (JetDirect) **no confirma nada**: acepta los bytes aunque después la impresora tire el
   trabajo. "Enviado" era un éxito fantasma.
3. Con autenticación de usuario activa, la Ricoh **descarta** los trabajos que llegan sin usuario válido
   (queda en el registro de trabajos como "error de autenticación").

## Por qué NO se puede "leer el usuario del WiFi"

Android 10+ e iOS **no permiten** a ninguna app leer la identidad/contraseña EAP del WiFi corporativo ni
las credenciales del dominio Windows. Es una restricción del sistema operativo, no de la app. Por eso se
hace igual que Mopria (Android) o AirPrint (iOS): **el usuario ingresa sus credenciales por impresora**
en Ajustes › Impresora › Acceso a la impresora; quedan cifradas en el almacén seguro del teléfono
(Keystore/Keychain), una por impresora, y nunca se escriben en logs.

## Qué soporta la app

| Impresora | Cómo se envía | Autenticación | Confirmación |
|---|---|---|---|
| Zebra (ZPL) | ZPL por 9100 (BT/USB igual que antes) | — | Consulta `~HS` por la misma conexión: papel, cabezal, cinta, pausa. Si no contesta: "no confirma" |
| Oficina + **IPP** (recomendado) | PDF (o PWG raster si no acepta PDF) por IPP en `http://IP:631/ipp/print` (prueba también `/ipp`, `/printer`, `/` y HTTPS 443/631) | HTTP **Basic** o **Digest** con usuario (`DOMINIO\usuario` si hay dominio) y contraseña | La impresora responde si **aceptó** el trabajo y su número: "La impresora aceptó el trabajo (#123)." |
| Oficina por **9100** | PCL 5 raster + cabecera PJL (`USERNAME`, `JOBNAME`, Ricoh `USERID` y `USERCODE`) | Solo **código de usuario** (Ricoh) | Ninguna: "Enviado. Esta impresora no confirma la impresión; revisá que haya salido." |

- La etiqueta para oficina se **dibuja en el teléfono** (fuera de pantalla, 4"×6" a 300 dpi, con el QR
  firmado real) y va centrada en una hoja A4 a su tamaño real.
- La prueba de impresión en oficina es una hoja simple: "Prueba DisTrack", fecha/hora y nombre del teléfono.
- **Límite honesto:** la autenticación Windows/LDAP de Ricoh **por PJL (9100)** no es posible: el driver
  de Ricoh manda usuario y contraseña cifrados con un algoritmo propietario no documentado. Por 9100 solo
  sirve el **código de usuario**. Para usuario + contraseña de dominio hace falta **IPP**.
- Kerberos/NTLM (Negotiate) no se pueden sin el sistema operativo: si la impresora solo ofrece eso, la app
  intenta Basic; si la impresora lo rechaza, hay que habilitar Basic/Digest para IPP.
- IPP va por socket propio (no `HttpClient`): la política de "solo HTTPS" de release es para el backend y
  bloquearía `http://` a la impresora de la LAN. Por HTTPS se acepta el certificado autofirmado de la
  impresora (solo contra su IP).
- **Al buscar impresoras nunca se mandan bytes al 9100.** La auto-detección del tipo usa solo IPP
  (Get-Printer-Attributes) y la página web de la impresora.

## Cómo configurar la Ricoh IM 550 (lo hace sistemas)

En **Web Image Monitor** (`http://192.168.2.154`, como administrador):

1. **Habilitar IPP**: Configuración › Interfaz/Red › Configuración de red › IPP = Activo (y, si se quiere,
   IPP-SSL/IPPS).
2. **Autenticación IPP**: Configuración › Seguridad › Autenticación de IPP → **Basic** (o Digest). Con
   autenticación de usuario (Windows/LDAP) activa, la Ricoh valida ese usuario/contraseña contra el AD.
3. Alternativa sin contraseña: **autenticación por código de usuario** y dar un código a cada operario; se
   puede usar por IPP o por 9100 (PJL `USERCODE`).
4. Alternativa de sistemas: **permitir trabajos sin autenticación** desde la red/VLAN del WiFi de andén
   (excepción por IP o "Trabajos de impresión sin autenticación"), si la política lo permite.
5. **Red**: el WiFi del teléfono (10.168.50.x) tiene que llegar a la red de cable de la impresora
   (192.168.2.x) por el **631** (IPP) o el **9100**. Si no hay ruta, ninguna configuración de la app sirve.

## Checklist de prueba en dispositivo

1. Ajustes › Impresora › WiFi › "Ingresar IP" → `192.168.2.154`, puerto 9100 → **Guardar**.
2. Debe aparecer "Acceso a la impresora" y la detección: "RICOH IM 550: impresora de oficina por IPP…".
   Si dice "No se pudo identificar", elegir a mano **Impresora de oficina (PDF)** e **IPP**.
3. Completar **Usuario** (viene prellenado con la parte local del email), **Dominio** (si la PC usa
   `DOMINIO\usuario`), **Contraseña**; o el **Código de usuario** si la Ricoh usa códigos.
4. **Probar impresión** → esperado: "La impresora aceptó el trabajo (#N)." y la hoja sale.
   - "La impresora pide usuario y contraseña…" → faltan credenciales.
   - "La impresora rechazó el usuario «DOMINIO\usuario»…" → usuario/clave incorrectos o Basic deshabilitado.
   - "No se pudo conectar a 192.168.2.154 por IPP" → IPP apagado o sin ruta al 631 (probar "Puerto 9100").
5. Con "Puerto 9100 (PCL)" + código de usuario: sale la hoja; el mensaje dice que la impresora no confirma.
6. En Preparar pedido: imprimir una etiqueta → sale en A4 con el QR; escanear ese QR con el chofer.
7. Zebra por WiFi: imprimir con la tapa abierta → "La impresora está … con el cabezal abierto…".

## Diagnóstico real: Ricoh IM 550 (192.168.2.154), 11-nov-2026

Consultada por IPP desde la PC de la oficina (misma red de cable), solo lectura salvo UN trabajo de prueba:

- `printer-make-and-model = RICOH IM 550 PS3`, `printer-state = idle`.
- `document-format-supported`: `application/pdf`, `application/octet-stream`, `image/jpeg`, `image/urf`, `application/postscript` (sin PWG raster).
- **`uri-authentication-supported = requesting-user-name`** (sin `basic`/`digest`).
- Trabajos que mandó el teléfono (#733–#741) y uno de prueba desde la PC (#744, PDF válido de 617 bytes,
  usuario `ehhuallata`): **todos** `job-state = 8 (aborted)`, `job-state-reasons = job-canceled-at-device`,
  `job-k-octets = 0`, `job-impressions-completed = 0`, creado/procesado/terminado en el mismo segundo.

**Conclusión:** la Ricoh tiene autenticación de usuarios (Windows/LDAP) y descarta todo trabajo IPP que no venga
autenticado. Por IPP solo acepta el nombre de usuario, sin contraseña, así que **ningún** cliente IPP (la app, un
iPhone con AirPrint, Mopria) puede imprimir. Desde la PC funciona porque el driver PCL de Ricoh manda usuario y
contraseña cifrados con su método propietario. **No es un bug de la app.**

### Qué tiene que hacer sistemas (una de estas)

1. **Habilitar la autenticación IPP** en Web Image Monitor → Configuración → Seguridad → *IPP Authentication*:
   Basic o Digest. Después la impresora publica `uri-authentication-supported = basic/digest` y la app usa el
   usuario de dominio y la contraseña cargados en Ajustes → Impresora → Acceso.
2. **Autenticación de trabajos "Simple (Limitación)"** (*Printer Job Authentication*) con el rango de IP de la red
   WiFi (`10.168.50.x`) habilitado para imprimir sin iniciar sesión.
3. **Códigos de usuario** en lugar de Windows: la app los manda por el puerto 9100 (PJL `USERCODE`).

En todos los casos hace falta además que la red WiFi tenga ruta hasta `192.168.2.154` (puertos 631 y/o 9100).

### Qué cambió en la app

"Aceptado" ya no se muestra como éxito: después del Print-Job la app consulta el trabajo (Get-Job-Attributes) hasta
su estado final y muestra **Impreso** (9), **Retenido: liberalo en el panel** (4), o el motivo de la cancelación
(7/8). En el caso de esta Ricoh dice: "La impresora canceló el trabajo: exige iniciar sesión para imprimir y por IPP
solo acepta el nombre de usuario, sin contraseña. Sistemas debe habilitar la Autenticación IPP…".
