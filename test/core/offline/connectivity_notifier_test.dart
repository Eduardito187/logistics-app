import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/offline/app_database.dart';
// offline_queue.dart reexporta connectivity_notifier.dart (connectivityProvider).
import 'package:logistics_app/core/offline/offline_queue.dart';
import 'package:logistics_app/core/offline/photo_upload_queue.dart';

// Nombres de canales de connectivity_plus (platform interface v2).
const _methodChannelName = 'dev.fluttercommunity.plus/connectivity';
const _eventChannelName = 'dev.fluttercommunity.plus/connectivity_status';

/// OfflineQueue espía: cuenta las llamadas a drain() sin tocar la red.
class _SpyOfflineQueue extends OfflineQueue {
  _SpyOfflineQueue(super.ref, super.db);
  int drains = 0;
  @override
  Future<void> drain() async {
    drains++;
  }
}

/// PhotoUploadQueue espía.
class _SpyPhotoQueue extends PhotoUploadQueue {
  _SpyPhotoQueue(super.ref, super.db);
  int drains = 0;
  @override
  Future<void> drain() async {
    drains++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late List<String> checkResult;
  late TestDefaultBinaryMessenger messenger;

  // Espías capturados cuando los providers se construyen bajo demanda.
  _SpyOfflineQueue? offlineSpy;
  _SpyPhotoQueue? photoSpy;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    checkResult = ['wifi'];
    offlineSpy = null;
    photoSpy = null;
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // checkConnectivity() → método 'check'.
    messenger.setMockMethodCallHandler(
      const MethodChannel(_methodChannelName),
      (call) async => call.method == 'check' ? checkResult : null,
    );
    // El stream de cambios: respondemos a listen/cancel sin emitir nada; los
    // eventos se inyectan a mano con [emit].
    messenger.setMockMethodCallHandler(
      const MethodChannel(_eventChannelName),
      (call) async => null,
    );
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(
      const MethodChannel(_methodChannelName),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel(_eventChannelName),
      null,
    );
    await db.close();
  });

  /// Empuja un evento de conectividad por el event channel y deja correr las
  /// microtareas (el drain se dispara con `unawaited`).
  Future<void> emit(List<String> statuses) async {
    await messenger.handlePlatformMessage(
      _eventChannelName,
      const StandardMethodCodec().encodeSuccessEnvelope(statuses),
      (_) {},
    );
    await pumpEventQueue();
  }

  ProviderContainer makeContainer({bool withSpies = false}) {
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (withSpies) ...[
          offlineQueueProvider.overrideWith(
            (ref) => offlineSpy = _SpyOfflineQueue(ref, db),
          ),
          photoUploadQueueProvider.overrideWith(
            (ref) => photoSpy = _SpyPhotoQueue(ref, db),
          ),
        ],
      ],
    );
  }

  group('build (estado inicial según checkConnectivity)', () {
    test('wifi → online (true)', () async {
      checkResult = ['wifi'];
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(connectivityProvider.future), isTrue);
    });

    test('none → offline (false)', () async {
      checkResult = ['none'];
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(connectivityProvider.future), isFalse);
    });

    test('mezcla con algo != none → online (true)', () async {
      checkResult = ['none', 'mobile'];
      final c = makeContainer();
      addTearDown(c.dispose);
      expect(await c.read(connectivityProvider.future), isTrue);
    });
  });

  group('cambios de conectividad', () {
    test('recuperar señal drena AMBAS colas (acciones y fotos)', () async {
      checkResult = ['none']; // arranca offline
      final c = makeContainer(withSpies: true);
      addTearDown(c.dispose);
      await c.read(connectivityProvider.future);

      await emit(['wifi']); // vuelve la señal

      expect(c.read(connectivityProvider).value, isTrue);
      expect(offlineSpy!.drains, 1);
      expect(photoSpy!.drains, 1);
    });

    test('perder señal NO drena', () async {
      checkResult = ['wifi']; // arranca online
      final c = makeContainer(withSpies: true);
      addTearDown(c.dispose);
      await c.read(connectivityProvider.future);

      await emit(['none']);

      expect(c.read(connectivityProvider).value, isFalse);
      // Los providers de cola ni siquiera se construyen al perder señal.
      expect(offlineSpy, isNull);
      expect(photoSpy, isNull);
    });

    test('tras dispose se cancela la suscripción (ya no drena)', () async {
      checkResult = ['none'];
      final c = makeContainer(withSpies: true);
      await c.read(connectivityProvider.future);
      c.dispose();

      await emit(['wifi']);

      // No se construyó ninguna cola porque _onChange ya no corre.
      expect(offlineSpy, isNull);
      expect(photoSpy, isNull);
    });
  });
}
