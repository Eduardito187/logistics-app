import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logistics_app/core/auth/biometric/biometric_capabilities.dart';
import 'package:logistics_app/core/auth/biometric/biometric_type.dart';
import 'package:logistics_app/core/icons/icons.dart';

// Textos de la biometría según lo que el teléfono REALMENTE tiene: nunca se
// nombra un sensor ausente (regla del dueño).

BiometricCapabilities _caps(
  Set<BiometricType> types, {
  TargetPlatform platform = TargetPlatform.android,
  bool enrolled = true,
}) => BiometricCapabilities(
  supported: true,
  enrolled: enrolled,
  types: types,
  platform: platform,
);

void main() {
  group('Android', () {
    test('solo huella → "huella"', () {
      final caps = _caps({BiometricType.fingerprint});
      expect(caps.label, 'huella');
      expect(caps.switchTitle, 'Ingresar con huella');
      expect(caps.labelWithArticle, 'tu huella');
      expect(
        caps.setupHint,
        'Configurá tu huella en los ajustes del teléfono para usarlo acá.',
      );
      expect(caps.appIcon, AppIcon.security);
    });

    test('solo rostro → "reconocimiento facial"', () {
      final caps = _caps({BiometricType.face});
      expect(caps.label, 'reconocimiento facial');
      expect(caps.switchTitle, 'Ingresar con reconocimiento facial');
      expect(caps.labelWithArticle, 'el reconocimiento facial');
      expect(caps.appIcon, AppIcon.profile);
    });

    test('huella + rostro → "huella o rostro"', () {
      final caps = _caps({BiometricType.face, BiometricType.fingerprint});
      expect(caps.label, 'huella o rostro');
      expect(caps.switchTitle, 'Ingresar con huella o rostro');
      expect(caps.appIcon, AppIcon.security);
    });

    test('incluye el iris cuando lo hay', () {
      expect(_caps({BiometricType.iris}).label, 'iris');
      expect(_caps({BiometricType.iris}).appIcon, AppIcon.visibility);
      expect(
        _caps({BiometricType.fingerprint, BiometricType.iris}).label,
        'huella o iris',
      );
      expect(
        _caps({
          BiometricType.iris,
          BiometricType.face,
          BiometricType.fingerprint,
        }).label,
        'huella, rostro o iris',
      );
    });

    test('soportado sin tipos detectados → "biometría del teléfono"', () {
      final caps = _caps({});
      expect(caps.label, 'biometría del teléfono');
      expect(caps.switchTitle, 'Ingresar con biometría del teléfono');
      expect(caps.labelWithArticle, 'la biometría del teléfono');
      expect(caps.appIcon, AppIcon.security);
    });
  });

  group('iOS', () {
    test('Face ID / Touch ID / Optic ID según el sensor', () {
      const ios = TargetPlatform.iOS;
      final face = _caps({BiometricType.face}, platform: ios);
      expect(face.label, 'Face ID');
      expect(face.switchTitle, 'Ingresar con Face ID');
      expect(
        face.setupHint,
        'Configurá Face ID en los ajustes del teléfono para usarlo acá.',
      );
      expect(face.appIcon, AppIcon.profile);
      expect(
        _caps({BiometricType.fingerprint}, platform: ios).label,
        'Touch ID',
      );
      expect(_caps({BiometricType.iris}, platform: ios).label, 'Optic ID');
    });

    test('sin tipo usa el nombre del sistema o el genérico', () {
      const withLabel = BiometricCapabilities(
        supported: true,
        enrolled: true,
        platformLabel: 'Face ID',
        platform: TargetPlatform.iOS,
      );
      expect(withLabel.label, 'Face ID');
      expect(
        _caps({}, platform: TargetPlatform.iOS).label,
        'biometría del teléfono',
      );
    });

    test('sin plataforma fija usa defaultTargetPlatform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        const caps = BiometricCapabilities(
          supported: true,
          enrolled: true,
          types: {BiometricType.face},
        );
        expect(caps.label, 'Face ID');
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(caps.label, 'reconocimiento facial');
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });

  group('fromMap', () {
    test('lee soportado, registrado y tipos; ignora tipos desconocidos', () {
      final caps = BiometricCapabilities.fromMap({
        'supported': true,
        'enrolled': true,
        'types': ['fingerprint', 'face', 'voz'],
        'platformLabel': null,
      });
      expect(caps.supported, isTrue);
      expect(caps.enrolled, isTrue);
      expect(caps.isAvailable, isTrue);
      expect(caps.types, {BiometricType.fingerprint, BiometricType.face});
      expect(caps.platformLabel, isNull);
    });

    test('sin hardware nunca queda "registrado"', () {
      final caps = BiometricCapabilities.fromMap({
        'supported': false,
        'enrolled': true,
      });
      expect(caps.supported, isFalse);
      expect(caps.enrolled, isFalse);
      expect(caps.isAvailable, isFalse);
    });

    test('soportado sin registrar no está disponible', () {
      final caps = BiometricCapabilities.fromMap({
        'supported': true,
        'enrolled': false,
        'types': 'basura',
      });
      expect(caps.supported, isTrue);
      expect(caps.isAvailable, isFalse);
      expect(caps.types, isEmpty);
    });

    test('igualdad por valor', () {
      expect(
        BiometricCapabilities.fromMap({
          'supported': true,
          'enrolled': true,
          'types': ['face'],
        }),
        const BiometricCapabilities(
          supported: true,
          enrolled: true,
          types: {BiometricType.face},
        ),
      );
    });
  });
}
