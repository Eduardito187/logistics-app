import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'power_status.dart';

/// Lector del canal nativo `bo.com.dismac/power` (Android `BatteryManager` +
/// `PowerManager.isPowerSaveMode`; iOS `UIDevice.batteryLevel` +
/// `ProcessInfo.isLowPowerModeEnabled`).
///
/// Nunca falla: sin canal (tests, escritorio, web → `MissingPluginException`)
/// o ante cualquier error devuelve [PowerStatus.unknown] y la app sigue con su
/// comportamiento normal.
class PowerChannel {
  const PowerChannel({MethodChannel channel = defaultChannel})
    : _channel = channel;

  static const MethodChannel defaultChannel = MethodChannel(
    'bo.com.dismac/power',
  );

  final MethodChannel _channel;

  Future<PowerStatus> read() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>('status');
      return PowerStatus.fromMap(map);
    } on Object {
      return PowerStatus.unknown;
    }
  }
}

final powerChannelProvider = Provider<PowerChannel>(
  (ref) => const PowerChannel(),
);
