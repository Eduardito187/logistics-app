# Makefile de logistics-app (app interna Flutter Dismac).
# Usa el Flutter de WSL (~/sdk/flutter). Ver CLAUDE.md para el detalle del entorno.
#
# Targets:
#   make format   -> dart format lib test
#   make analyze  -> flutter analyze
#   make test     -> flutter test
#   make gen      -> regenera el cliente del API (scripts/regen_api_client.sh)
#   make ci       -> format check + analyze + test (lo mismo que corre CI)

# Flutter de WSL al frente del PATH para todas las recetas.
export PATH := $(HOME)/sdk/flutter/bin:$(PATH)

.PHONY: format analyze test gen ci

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
