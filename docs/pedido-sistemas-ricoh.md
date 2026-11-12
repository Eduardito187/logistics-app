# Pedido a Sistemas: habilitar la impresión desde la app DisTrack en la Ricoh IM 550

**Equipo:** RICOH IM 550 (PS3/PCL 6) · IP `192.168.2.154` · red de cable `192.168.2.x`
**Quién imprime:** celulares de la app interna DisTrack, conectados al WiFi `10.168.50.x`
**Fecha del diagnóstico:** 11-nov-2026

## Qué pasa hoy (verificado)

- Los trabajos de la app **llegan** a la Ricoh por IPP (puerto 631) con el usuario del operario
  (`requesting-user-name`, p. ej. `ehhuallata`).
- La Ricoh los **cancela al instante**: `job-state = aborted`, `job-state-reasons = job-canceled-at-device`,
  0 KB, 0 hojas (trabajos #733–#759).
- La Ricoh publica `uri-authentication-supported = requesting-user-name`: por IPP no admite contraseña.
- Una prueba por el puerto 9100 con el usuario en PJL (`@PJL SET USERID`) **tampoco** llega a la lista de
  impresión retenida del usuario.
- Desde Windows sí funciona porque el driver Ricoh PCL 6 envía usuario y contraseña cifrados con el método
  propietario de Ricoh, que un celular no puede reproducir.

Es decir: la Ricoh exige **autenticación completa** para cualquier trabajo de impresión, y ningún cliente que
no sea el driver de Windows (celulares, AirPrint, Mopria, la app) puede cumplirla.

## Qué se pide (cualquiera de estas opciones; la 1 es la recomendada)

### Opción 1 (recomendada): autenticación "Simple (Limitación)" para la red WiFi

Web Image Monitor → *Gestión de dispositivos* → *Configuración* → *Gestión de autenticación de usuario* →
**Autenticación de trabajos de impresora**: `Simple (Limitación)`, agregando el rango
**`10.168.50.1` – `10.168.50.254`**.

- Los trabajos que vienen de ese rango se aceptan **con el nombre de usuario** (sin contraseña) y, como hoy,
  quedan **retenidos en la lista del usuario**: para imprimirlos, el operario igual se identifica con su
  código en el panel. **No se pierde seguridad**: nadie imprime sin identificarse frente a la impresora.
- La PC y el resto de la red siguen exactamente igual.

### Opción 2: autenticación IPP con contraseña

Web Image Monitor → *Configuración* → *Seguridad* / *IPP* → **Autenticación IPP: Basic o Digest**, con los
mismos usuarios del dominio. La app ya envía el usuario y la contraseña que el operario carga una vez.
(Si la Ricoh valida contra LDAP/Windows, confirmar que la autenticación IPP use esa misma base.)

### Opción 3: códigos de usuario

Si la Ricoh pasa a autenticar con **código de usuario**, la app ya envía el código (PJL `USERCODE`) por el
puerto 9100.

## En todos los casos

- La red WiFi `10.168.50.x` debe poder llegar a `192.168.2.154` por **TCP 631** (IPP; recomendado porque
  confirma el resultado) y/o **TCP 9100**.

## Cómo verificamos después

Desde la app: *Ajustes → Impresora → Imprimir prueba*. Con la opción 1 la app debe mostrar
**"La impresora retuvo el trabajo: liberalo desde el panel de la impresora con tu usuario"** y el trabajo
aparece en la lista del operario. Desde la PC de la oficina también se puede consultar el estado por IPP
(sin imprimir) para confirmar que ya no se cancelan.
