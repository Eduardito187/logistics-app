// GENERADO por tool/icons/gen_icons.py desde tool/icons/catalog.json y tool/icons/svg/.
// NO editar a mano: cambiar el SVG/catálogo y regenerar.

import 'package:flutter/material.dart';

/// Íconos custom DisTrack de la app. Cada uno reemplaza a uno o más `Icons.*`
/// de Material ([fallback] es el primero, usado si faltara el dibujo).
enum AppIcon {
  /// Inicio · lote nav · reemplaza: home_outlined, home_rounded
  home(Icons.home_outlined, 'Inicio'),

  /// Tareas · lote nav · reemplaza: grid_view_outlined, grid_view_rounded
  tasks(Icons.grid_view_outlined, 'Tareas'),

  /// Avisos · lote nav · reemplaza: notifications_outlined, notifications_rounded, notifications_none
  alerts(Icons.notifications_outlined, 'Avisos'),

  /// Perfil · lote nav · reemplaza: person_outline_rounded, person_rounded, person_outline, account_circle
  profile(Icons.person_outline_rounded, 'Perfil'),

  /// Entrega en curso · lote role · reemplaza: local_shipping, local_shipping_outlined
  deliver(Icons.local_shipping, 'Entrega en curso'),

  /// Mi ruta de hoy · lote role · reemplaza: route
  route(Icons.route, 'Mi ruta de hoy'),

  /// Mapa · lote role · reemplaza: map, map_outlined
  map(Icons.map, 'Mapa'),

  /// Mi día · lote role · reemplaza: today, calendar_today, event_available
  myDay(Icons.today, 'Mi día'),

  /// Checklist · lote role · reemplaza: checklist, playlist_add_check, fact_check_outlined
  checklist(Icons.checklist, 'Checklist'),

  /// Carga del camión · lote role · reemplaza: upload
  load(Icons.upload, 'Carga del camión'),

  /// Rastreo GPS · lote role · reemplaza: my_location, gps_fixed, gps_not_fixed
  gps(Icons.my_location, 'Rastreo GPS'),

  /// Incidente · lote role · reemplaza: report, report_outlined, report_problem_outlined, report_gmailerrorred, warning_amber_rounded, car_crash_outlined, assignment_late_outlined
  incident(Icons.report, 'Incidente'),

  /// Resumen del vehículo · lote role · reemplaza: insights
  vehicleSummary(Icons.insights, 'Resumen del vehículo'),

  /// Combustible · lote role · reemplaza: local_gas_station
  fuel(Icons.local_gas_station, 'Combustible'),

  /// Pedidos · lote role · reemplaza: list_alt, list
  orders(Icons.list_alt, 'Pedidos'),

  /// Escanear · lote role · reemplaza: qr_code_scanner
  scan(Icons.qr_code_scanner, 'Escanear'),

  /// Código QR · lote state · reemplaza: qr_code_2, qr_code
  qrCode(Icons.qr_code_2, 'Código QR'),

  /// Recepción de mercadería · lote role · reemplaza: inventory_2, inventory_2_outlined, inventory
  receive(Icons.inventory_2, 'Recepción de mercadería'),

  /// Recojo en tienda · lote role · reemplaza: storefront, store
  pickupStore(Icons.storefront, 'Recojo en tienda'),

  /// Escanear al recoger · lote role · reemplaza: upload_file
  pickupScan(Icons.upload_file, 'Escanear al recoger'),

  /// Escanear al entregar · lote role · reemplaza: task_alt
  deliverScan(Icons.task_alt, 'Escanear al entregar'),

  /// Liquidaciones · lote role · reemplaza: receipt_long
  settle(Icons.receipt_long, 'Liquidaciones'),

  /// Tablero del día · lote role · reemplaza: dashboard
  dashboard(Icons.dashboard, 'Tablero del día'),

  /// Flota en vivo · lote role · reemplaza: —
  fleet(Icons.circle_outlined, 'Flota en vivo'),

  /// Rutas en curso · lote role · reemplaza: alt_route
  plans(Icons.alt_route, 'Rutas en curso'),

  /// Alertas · lote role · reemplaza: notification_important, notifications_active
  roleAlerts(Icons.notification_important, 'Alertas'),

  /// Listo · lote state · reemplaza: check_circle, check_circle_outline
  success(Icons.check_circle, 'Listo'),

  /// Hecho · lote state · reemplaza: check, done_all
  check(Icons.check, 'Hecho'),

  /// Verificado · lote state · reemplaza: verified, verified_user_outlined, shield_outlined
  verified(Icons.verified, 'Verificado'),

  /// Error · lote state · reemplaza: error, error_outline
  error(Icons.error, 'Error'),

  /// Rechazado · lote state · reemplaza: cancel, cancel_outlined, block
  cancel(Icons.cancel, 'Rechazado'),

  /// Pendiente · lote state · reemplaza: schedule, timer_outlined, hourglass_bottom, pending_actions
  pending(Icons.schedule, 'Pendiente'),

  /// Sincronizando · lote state · reemplaza: sync, autorenew
  syncing(Icons.sync, 'Sincronizando'),

  /// Actualizar · lote state · reemplaza: refresh, restart_alt
  refresh(Icons.refresh, 'Actualizar'),

  /// Sincronizado · lote state · reemplaza: cloud_done
  cloudDone(Icons.cloud_done, 'Sincronizado'),

  /// Sin conexión · lote state · reemplaza: cloud_off
  cloudOff(Icons.cloud_off, 'Sin conexión'),

  /// Wi-Fi · lote state · reemplaza: wifi
  wifi(Icons.wifi, 'Wi-Fi'),

  /// Sin Wi-Fi · lote state · reemplaza: wifi_off
  wifiOff(Icons.wifi_off, 'Sin Wi-Fi'),

  /// Ubicación · lote state · reemplaza: place, location_on, location_on_outlined, pin_drop
  place(Icons.place, 'Ubicación'),

  /// Sin ubicación · lote state · reemplaza: gps_off, location_off
  gpsOff(Icons.gps_off, 'Sin ubicación'),

  /// Navegación · lote state · reemplaza: navigation, navigation_outlined
  navigation(Icons.navigation, 'Navegación'),

  /// Imprimir · lote state · reemplaza: print
  printing(Icons.print, 'Imprimir'),

  /// Foto · lote state · reemplaza: photo_camera, camera_alt
  capture(Icons.photo_camera, 'Foto'),

  /// Cambiar cámara · lote state · reemplaza: cameraswitch
  cameraSwitch(Icons.cameraswitch, 'Cambiar cámara'),

  /// Imagen · lote state · reemplaza: image_outlined, broken_image_outlined
  image(Icons.image_outlined, 'Imagen'),

  /// Firma · lote state · reemplaza: draw, edit_note
  signature(Icons.draw, 'Firma'),

  /// Seguridad · lote state · reemplaza: lock_outline
  security(Icons.lock_outline, 'Seguridad'),

  /// Credencial · lote state · reemplaza: badge_outlined
  badge(Icons.badge_outlined, 'Credencial'),

  /// Acción rápida · lote state · reemplaza: bolt, flash_on
  bolt(Icons.bolt, 'Acción rápida'),

  /// Iniciar · lote state · reemplaza: play_circle_outline
  play(Icons.play_circle_outline, 'Iniciar'),

  /// Avisos silenciados · lote state · reemplaza: notifications_off, notifications_off_outlined
  alertsOff(Icons.notifications_off, 'Avisos silenciados'),

  /// Velocidad · lote state · reemplaza: speed
  speed(Icons.speed, 'Velocidad'),

  /// Ver más · lote util · reemplaza: chevron_right
  chevronRight(Icons.chevron_right, 'Ver más'),

  /// Siguiente · lote util · reemplaza: arrow_forward, arrow_forward_rounded
  arrowForward(Icons.arrow_forward, 'Siguiente'),

  /// Desplegar · lote util · reemplaza: expand_more
  expandMore(Icons.expand_more, 'Desplegar'),

  /// Cerrar · lote util · reemplaza: close
  close(Icons.close, 'Cerrar'),

  /// Agregar · lote util · reemplaza: add
  add(Icons.add, 'Agregar'),

  /// Quitar · lote util · reemplaza: remove
  remove(Icons.remove, 'Quitar'),

  /// Buscar · lote util · reemplaza: search
  search(Icons.search, 'Buscar'),

  /// Ajustes · lote util · reemplaza: settings
  settings(Icons.settings, 'Ajustes'),

  /// Cerrar sesión · lote util · reemplaza: logout
  logout(Icons.logout, 'Cerrar sesión'),

  /// Llamar · lote util · reemplaza: call, phone
  call(Icons.call, 'Llamar'),

  /// Teléfono · lote util · reemplaza: phone_android, phone_iphone, smartphone
  phone(Icons.phone_android, 'Teléfono'),

  /// Correo · lote util · reemplaza: mail_outline
  mail(Icons.mail_outline, 'Correo'),

  /// Enviar · lote util · reemplaza: send
  send(Icons.send, 'Enviar'),

  /// Soporte · lote util · reemplaza: support_agent
  support(Icons.support_agent, 'Soporte'),

  /// Acuerdo · lote util · reemplaza: handshake
  handshake(Icons.handshake, 'Acuerdo'),

  /// Herramientas · lote util · reemplaza: build
  build(Icons.build, 'Herramientas'),

  /// Ahorro · lote util · reemplaza: savings
  savings(Icons.savings, 'Ahorro'),

  /// Pagos · lote util · reemplaza: payments, payments_outlined, price_change_outlined
  payments(Icons.payments, 'Pagos'),

  /// Supervisor · lote util · reemplaza: supervisor_account
  supervisor(Icons.supervisor_account, 'Supervisor'),

  /// Sin usuario · lote util · reemplaza: person_off, person_off_outlined
  personOff(Icons.person_off, 'Sin usuario'),

  /// Dispositivos · lote util · reemplaza: devices, devices_other, computer
  devices(Icons.devices, 'Dispositivos'),

  /// Red cableada · lote util · reemplaza: lan, settings_ethernet
  lan(Icons.lan, 'Red cableada'),

  /// USB · lote util · reemplaza: usb
  usb(Icons.usb, 'USB'),

  /// Bluetooth · lote util · reemplaza: bluetooth
  bluetooth(Icons.bluetooth, 'Bluetooth'),

  /// Actualización · lote util · reemplaza: system_update
  systemUpdate(Icons.system_update, 'Actualización'),

  /// Descargar · lote util · reemplaza: download
  download(Icons.download, 'Descargar'),

  /// Guardar · lote util · reemplaza: save
  save(Icons.save, 'Guardar'),

  /// Copiar · lote util · reemplaza: copy_outlined
  copy(Icons.copy_outlined, 'Copiar'),

  /// Eliminar · lote util · reemplaza: delete_outline
  delete(Icons.delete_outline, 'Eliminar'),

  /// Mostrar · lote util · reemplaza: visibility_outlined
  visibility(Icons.visibility_outlined, 'Mostrar'),

  /// Ocultar · lote util · reemplaza: visibility_off_outlined
  visibilityOff(Icons.visibility_off_outlined, 'Ocultar'),

  /// PIN · lote util · reemplaza: pin_outlined
  pin(Icons.pin_outlined, 'PIN'),

  /// Teclado · lote util · reemplaza: keyboard
  keyboard(Icons.keyboard, 'Teclado'),

  /// Nueva etiqueta · lote util · reemplaza: new_label
  newLabel(Icons.new_label, 'Nueva etiqueta'),

  /// Etiqueta anulada · lote util · reemplaza: label_off
  labelOff(Icons.label_off, 'Etiqueta anulada'),

  /// Bandera · lote util · reemplaza: flag
  flag(Icons.flag, 'Bandera'),

  /// Intercambiar · lote util · reemplaza: swap_horiz
  swap(Icons.swap_horiz, 'Intercambiar'),

  /// Ver todo · lote util · reemplaza: zoom_out_map
  zoomOut(Icons.zoom_out_map, 'Ver todo'),

  /// Modo sol · lote util · reemplaza: wb_sunny_outlined
  sun(Icons.wb_sunny_outlined, 'Modo sol'),

  /// Vibración · lote util · reemplaza: vibration
  vibration(Icons.vibration, 'Vibración'),

  /// Salida · lote util · reemplaza: outbound_outlined
  outbound(Icons.outbound_outlined, 'Salida'),

  /// Sin marcar · lote util · reemplaza: radio_button_unchecked
  radioUnchecked(Icons.radio_button_unchecked, 'Sin marcar'),

  /// Bandeja · lote util · reemplaza: inbox_outlined
  inbox(Icons.inbox_outlined, 'Bandeja');

  const AppIcon(this.fallback, this.label);

  /// Ícono Material equivalente (fallback mientras no exista el dibujo).
  final IconData fallback;

  /// Etiqueta en español para lectores de pantalla.
  final String label;
}
