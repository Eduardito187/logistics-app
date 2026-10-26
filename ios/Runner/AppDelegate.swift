import Flutter
import UIKit
import flutter_foreground_task
import workmanager_apple

/// Identificador BGTaskScheduler de la sincronización de la cola offline.
/// Debe coincidir con `BGTaskSchedulerPermittedIdentifiers` (Info.plist) y con el
/// `uniqueName`/identificador que el código Dart pasa a `Workmanager().registerPeriodicTask`.
let kSyncTaskIdentifier = "bo.com.dismac.logisticsApp.sync"

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Isolates en segundo plano (workmanager / foreground task) necesitan los
    // plugins registrados para poder usar Drift, red, GPS, etc.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // iOS exige registrar los handlers de BGTaskScheduler ANTES de terminar el
    // arranque; si se registran después (desde Dart) la app se cierra con
    // NSInternalInconsistencyException. 15 min es el mínimo útil en iOS.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: kSyncTaskIdentifier,
      earliestBeginInSeconds: NSNumber(value: 15 * 60)
    )

    // Memoria del teléfono para que Dart ajuste cachés (lib/core/performance).
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "bo.com.dismac/device_memory",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "info" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let totalMb = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        // iPhone 6/6 Plus/SE 1ra gen: 1–2 GB. Se trata como gama baja ≤ 1,5 GB.
        result(["totalMb": totalMb, "lowRam": totalMb <= 1536])
      }
    }

    // Notificaciones locales/push en primer plano (flutter_local_notifications,
    // firebase_messaging y flutter_foreground_task).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
