import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/push/firebase_options.dart';

void main() {
  FirebaseOptions? build(
    TargetPlatform platform, {
    String apiKey = 'android-key',
    String iosApiKey = '',
    String androidAppId = '1:123:android:abc',
    String iosAppId = '1:123:ios:def',
    String iosBundleId = 'bo.com.dismac.logisticsApp',
    String senderId = '123',
    String projectId = 'dismac-logistics',
  }) => buildFirebaseOptions(
    platform: platform,
    apiKey: apiKey,
    iosApiKey: iosApiKey,
    androidAppId: androidAppId,
    iosAppId: iosAppId,
    iosBundleId: iosBundleId,
    messagingSenderId: senderId,
    projectId: projectId,
  );

  group('buildFirebaseOptions', () {
    test('Android usa el appId de Android y no manda bundle id', () {
      final options = build(TargetPlatform.android)!;
      expect(options.appId, '1:123:android:abc');
      expect(options.apiKey, 'android-key');
      expect(options.iosBundleId, isNull);
      expect(options.messagingSenderId, '123');
      expect(options.projectId, 'dismac-logistics');
    });

    test('iOS usa el appId y el bundle id de iOS', () {
      final options = build(TargetPlatform.iOS)!;
      expect(options.appId, '1:123:ios:def');
      expect(options.iosBundleId, 'bo.com.dismac.logisticsApp');
    });

    test('iOS usa su propia API key si está configurada', () {
      expect(build(TargetPlatform.iOS)!.apiKey, 'android-key');
      expect(
        build(TargetPlatform.iOS, iosApiKey: 'ios-key')!.apiKey,
        'ios-key',
      );
      expect(
        build(TargetPlatform.android, iosApiKey: 'ios-key')!.apiKey,
        'android-key',
      );
    });

    test('iOS sin bundle id lo deja nulo', () {
      expect(build(TargetPlatform.iOS, iosBundleId: '')!.iosBundleId, isNull);
    });

    test('sin appId de la plataforma el push queda desactivado', () {
      expect(build(TargetPlatform.iOS, iosAppId: ''), isNull);
      expect(build(TargetPlatform.android, androidAppId: ''), isNull);
      // El appId de la otra plataforma no alcanza.
      expect(build(TargetPlatform.android, iosAppId: ''), isNotNull);
      expect(build(TargetPlatform.iOS, androidAppId: ''), isNotNull);
    });

    test('faltando cualquier credencial común devuelve null', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        expect(build(platform, apiKey: ''), isNull);
        expect(build(platform, senderId: ''), isNull);
        expect(build(platform, projectId: ''), isNull);
      }
    });
  });

  test('firebaseOptionsFromConfig es null sin credenciales en el build', () {
    // Los tests corren sin --dart-define-from-file: todas las FIREBASE_* vacías.
    expect(firebaseOptionsFromConfig(), isNull);
  });
}
