import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/breakpoints.dart';
import '../../../core/layout/responsive_body.dart';

import '../../../core/api/export.dart';
import '../../../core/commands/command_feedback.dart';
import '../../../core/commands/command_outcome.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_snack.dart';
import '../../../core/widgets/section_card.dart';
import '../domain/usecases/record_refuel.dart';
import 'controllers/fleet_ops_controllers.dart';
import 'driver_vehicle_gate.dart';
import 'fleet_ops_common.dart';
import 'widgets/price_hint.dart';
import 'widgets/recent_refuels.dart';

/// Carga de combustible del vehículo del chofer. Escritura con red (no es un
/// escaneo offline). El backend responde 202 (`AcceptedEnvelope`): acepta la
/// carga pero la procesa de forma asíncrona, así que se avisa "en proceso" (no
/// un éxito aplicado) y se invalida la lista para que se refresque cuando el
/// backend la procese. Muestra el precio vigente como ayuda y las cargas
/// recientes.
class FuelScreen extends ConsumerStatefulWidget {
  const FuelScreen({super.key});

  @override
  ConsumerState<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends ConsumerState<FuelScreen> {
  static const String _currency = 'BOB';

  FuelType _fuelType = FuelType.diesel;
  final TextEditingController _liters = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _odometer = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _fullTank = true;
  bool _busy = false;

  @override
  void dispose() {
    _liters.dispose();
    _price.dispose();
    _odometer.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DriverVehicleGate(
      title: 'Cargar combustible',
      builder: (context, vehicleId) {
        final priceAsync = ref.watch(currentFuelPriceProvider(_fuelType));
        return ResponsiveBody(
          maxWidth: AppBreakpoints.maxFormWidth,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: 'Datos de la carga',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<FuelType>(
                      value: _fuelType,
                      // isExpanded: el ítem ocupa el ancho del campo y se corta
                      // con elipsis (sin esto desborda en 320 dp con letra 1.3x).
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de combustible',
                      ),
                      items: [
                        for (final type in FuelType.$valuesDefined)
                          DropdownMenuItem<FuelType>(
                            value: type,
                            child: Text(fuelTypeLabel(type)),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _fuelType = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    PriceHint(
                      value: priceAsync,
                      onUse: (cents) {
                        _price.text = (cents / 100).toStringAsFixed(2);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _liters,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_decimalInput],
                      decoration: const InputDecoration(
                        labelText: 'Litros',
                        suffixText: 'L',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [_decimalInput],
                      decoration: const InputDecoration(
                        labelText: 'Precio por litro',
                        prefixText: '$_currency ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _odometer,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Odómetro actual (opcional)',
                        suffixText: 'km',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _note,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tanque lleno'),
                      value: _fullTank,
                      onChanged: _busy
                          ? null
                          : (value) => setState(() => _fullTank = value),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _submit(vehicleId),
                      icon: _busy
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.local_gas_station),
                      label: Text(_busy ? 'Registrando…' : 'Registrar carga'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const RecentRefuels(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit(String vehicleId) async {
    final liters = double.tryParse(_liters.text.trim());
    final price = double.tryParse(_price.text.trim());
    if (liters == null || liters <= 0) {
      showErrorSnack(context, 'Ingresa los litros cargados.');
      return;
    }
    if (price == null || price <= 0) {
      showErrorSnack(context, 'Ingresa el precio por litro.');
      return;
    }
    final odometerKm = int.tryParse(_odometer.text.trim());
    final note = _note.text.trim();

    setState(() => _busy = true);
    try {
      // La llamada al backend vive en la capa de datos (caso de uso); la UI no
      // toca el API directamente. El backend responde 202 async: no está
      // aplicada todavía.
      final envelope = await ref
          .read(recordRefuelProvider)
          .call(
            vehicleId: vehicleId,
            fuelType: _fuelType,
            liters: liters,
            pricePerLiterCents: (price * 100).round(),
            currency: _currency,
            fullTank: _fullTank,
            refueledAt: DateTime.now(),
            odometerKm: odometerKm,
            note: note.isEmpty ? null : note,
          );
      if (!mounted) return;
      // Se invalida para que la lista se refresque cuando el backend procese.
      ref.invalidate(vehicleRefuelsProvider);
      _liters.clear();
      _price.clear();
      _odometer.clear();
      _note.clear();
      showCommandOutcome(context, CommandOutcome.fromAccepted(envelope));
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// Solo dígitos y punto decimal (creado una vez, no en cada build).
final TextInputFormatter _decimalInput = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9.]'),
);
