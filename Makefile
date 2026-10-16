# Makefile de logistics-app (app interna Flutter Dismac).
# Usa el Flutter de WSL (~/sdk/flutter). Ver CLAUDE.md para el detalle del entorno.
#
# Targets:
#   make format   -> dart format lib test
#   make analyze  -> flutter analyze
#   make test     -> flutter test
#   make gen      -> regenera el cliente del API (scripts/regen_api_client.sh)
#   make ci       -> format check + analyze + test (lo mismo que corre CI)
#   make apk      -> APK release por arquitectura (ENV=dev|staging|production)
#   make e2e      -> tests de integración (DEVICE=flutter-tester|<id>, ver docs/e2e.md)
#
# `make apk` usa --split-per-abi: un APK por ABI (arm64-v8a, armeabi-v7a,
# x86_64) ~3x más chico que el "fat APK". Los teléfonos Android Go de 1 GB
# suelen ser armeabi-v7a (32 bits); el resto, arm64-v8a.
# Ver docs/rendimiento-y-pantallas.md.

# Flutter de WSL al frente del PATH para todas las recetas.
export PATH := $(HOME)/sdk/flutter/bin:$(PATH)

.PHONY: format analyze test gen ci apk

ENV ?= dev

format:
	dart format lib test

analyze:
	flutter analyze

test:
	flutter test

gen:
	bash scripts/regen_api_client.sh

# CI: el formato no debe tener cambios pendientes, luego analyze y test.
ci:
	dart format --output=none --set-exit-if-changed lib test
	flutter analyze
	flutter test

# APK release por arquitectura. Una sola build a la vez (Gradle ya colgó la
# máquina con builds apiladas).
apk:
	flutter build apk --release --split-per-abi --dart-define-from-file=config/$(ENV).json

# Tests de integración (e2e) de los 4 flujos críticos. Ver docs/e2e.md.
#   make e2e                                -> en el host (flutter-tester)
#   make e2e DEVICE=emulator-5554 ENV=dev   -> en un emulador/teléfono
# Un solo dispositivo y una sola corrida a la vez (RAM justa).
.PHONY: e2e
DEVICE ?= flutter-tester
e2e:
	flutter test integration_test -d $(DEVICE) $(if $(filter flutter-tester,$(DEVICE)),,--dart-define-from-file=config/$(ENV).json)
