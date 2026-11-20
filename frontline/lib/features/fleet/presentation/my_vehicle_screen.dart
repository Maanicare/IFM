import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import 'trip_controller.dart';

/// SCREEN 48 (driver subset) - assigned vehicle identity/compliance
/// dates, and the one thing a driver actually does day to day: start/
/// end a trip with an odometer reading. Fleet-wide views stay out of
/// scope here (Screen 47 is a Fleet Manager/desktop concern).
class MyVehicleScreen extends ConsumerWidget {
  const MyVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicle')),
      body: driverId == null
          ? const SizedBox.shrink()
          : _VehicleContent(driverId: driverId),
    );
  }
}

class _VehicleContent extends ConsumerWidget {
  const _VehicleContent({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(_vehicleProvider(driverId));

    return vehicleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (vehicle) {
        if (vehicle == null) {
          return const Center(child: Text('No vehicle assigned to you.'));
        }
        final fmt = DateFormat.yMMMd();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.registration, style: Theme.of(context).textTheme.titleLarge),
                    Text('${vehicle.make ?? ''} ${vehicle.model ?? ''} · ${vehicle.type.replaceAll('_', ' ')}'),
                    const SizedBox(height: 8),
                    Text('Odometer: ${vehicle.odometer?.toStringAsFixed(0) ?? '-'} km'),
                    Text('Status: ${vehicle.status}'),
                    if (vehicle.insuranceExpiry != null)
                      Text('Insurance expiry: ${fmt.format(vehicle.insuranceExpiry!)}'),
                    if (vehicle.pucExpiry != null) Text('PUC expiry: ${fmt.format(vehicle.pucExpiry!)}'),
                    if (vehicle.serviceDueDate != null)
                      Text('Service due: ${fmt.format(vehicle.serviceDueDate!)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _TripSection(vehicle: vehicle, driverId: driverId),
            const SizedBox(height: 16),
            _TripHistorySection(driverId: driverId),
          ],
        );
      },
    );
  }
}

/// Screen 48: "Trip history". The open/active trip is handled by
/// [_TripSection] above; this lists completed trips, most recent first.
class _TripHistorySection extends ConsumerWidget {
  const _TripHistorySection({required this.driverId});
  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = (ref.watch(_tripsProvider(driverId)).value ?? const [])
        .where((t) => t.endTime != null)
        .toList();
    if (trips.isEmpty) return const SizedBox.shrink();

    final fmt = DateFormat.yMMMd().add_Hm();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip history', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final trip in trips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fmt.format(trip.startTime)} → ${fmt.format(trip.endTime!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${trip.startOdometer.toStringAsFixed(0)} → '
                      '${trip.endOdometer!.toStringAsFixed(0)} km'
                      '${trip.fuelUsed != null ? ' · ${trip.fuelUsed!.toStringAsFixed(1)} L fuel' : ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final _tripsProvider = StreamProvider.family<List<Trip>, String>((ref, driverId) {
  return ref.watch(appDatabaseProvider).fleetDao.watchTripsForDriver(driverId);
});

final _vehicleProvider = StreamProvider.family<Vehicle?, String>((ref, driverId) {
  return ref.watch(appDatabaseProvider).fleetDao.watchAssignedVehicle(driverId);
});

class _TripSection extends ConsumerStatefulWidget {
  const _TripSection({required this.vehicle, required this.driverId});
  final Vehicle vehicle;
  final String driverId;

  @override
  ConsumerState<_TripSection> createState() => _TripSectionState();
}

class _TripSectionState extends ConsumerState<_TripSection> {
  final _odometerController = TextEditingController();
  final _fuelController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _odometerController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  Future<void> _startTrip() async {
    final odometer = double.tryParse(_odometerController.text);
    if (odometer == null) return;
    setState(() => _submitting = true);
    await ref.read(tripControllerProvider.notifier).startTrip(
          vehicleId: widget.vehicle.id,
          startOdometer: odometer,
        );
    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _endTrip(String tripId) async {
    final odometer = double.tryParse(_odometerController.text);
    if (odometer == null) return;
    setState(() => _submitting = true);
    await ref.read(tripControllerProvider.notifier).endTrip(
          tripId: tripId,
          endOdometer: odometer,
          fuelUsed: double.tryParse(_fuelController.text),
        );
    _odometerController.clear();
    _fuelController.clear();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final openTrip = ref.watch(_openTripProvider(widget.driverId)).value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (openTrip != null)
              Text('In progress since ${DateFormat.Hm().format(openTrip.startTime)}'),
            const SizedBox(height: 8),
            TextField(
              controller: _odometerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: openTrip == null ? 'Start odometer' : 'End odometer'),
            ),
            if (openTrip != null) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _fuelController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Fuel used (optional)'),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : (openTrip == null ? _startTrip : () => _endTrip(openTrip.id)),
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(openTrip == null ? 'Start trip' : 'End trip'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _openTripProvider = StreamProvider.family<Trip?, String>((ref, driverId) {
  return ref.watch(appDatabaseProvider).fleetDao.watchOpenTrip(driverId);
});
