import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../location/presentation/current_site_provider.dart';
import 'reservation_controller.dart';

/// SCREEN 43 - Reservation (space detail). Display: Capacity; Equipment;
/// Amenities; Temperature/IAQ if available (not shown - no sensor data
/// exists, see the doc comment on [Reservations]). Actions: Reserve;
/// Invite; Order services; Check in.
class SpaceReservationDetailScreen extends ConsumerWidget {
  const SpaceReservationDetailScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceAsync = ref.watch(_spaceProvider(spaceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Space')),
      body: spaceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (space) {
          if (space == null) return const Center(child: Text('Not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(space.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _FieldsCard(space: space),
              const SizedBox(height: 12),
              _TodayBookingsSection(spaceId: space.id),
              const SizedBox(height: 16),
              _ReserveForm(space: space),
            ],
          );
        },
      ),
    );
  }
}

class _FieldsCard extends StatelessWidget {
  const _FieldsCard({required this.space});
  final Space space;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String?)>[
      if (space.capacity != null) ('Capacity', '${space.capacity}'),
      ('Equipment', space.equipmentNote),
      ('Amenities', space.amenitiesNote),
    ].where((r) => r.$2 != null).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
                    Expanded(child: Text(value!)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TodayBookingsSection extends ConsumerWidget {
  const _TodayBookingsSection({required this.spaceId});
  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(_bookingsProvider(spaceId)).value ?? const [];
    if (bookings.isEmpty) return const SizedBox.shrink();
    final fmt = DateFormat.Hm();
    final accessContext = ref.watch(authControllerProvider).value;
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's bookings", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final r in bookings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${fmt.format(r.startTime)}-${fmt.format(r.endTime)} · ${r.purpose ?? "Reserved"}',
                      ),
                    ),
                    if (r.organiserId == accessContext?.id && !r.checkedIn && siteId != null)
                      TextButton(
                        onPressed: () =>
                            ref.read(reservationControllerProvider.notifier).checkIn(r.id, siteId: siteId),
                        child: const Text('Check in'),
                      ),
                    if (r.checkedIn) const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReserveForm extends ConsumerStatefulWidget {
  const _ReserveForm({required this.space});
  final Space space;

  @override
  ConsumerState<_ReserveForm> createState() => _ReserveFormState();
}

class _ReserveFormState extends ConsumerState<_ReserveForm> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(hours: 1));
  final _purposeController = TextEditingController();
  final _attendeesController = TextEditingController();
  final _inviteesController = TextEditingController();
  final _servicesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    _attendeesController.dispose();
    _inviteesController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final now = DateTime.now();
    final combined = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _start = combined;
      } else {
        _end = combined;
      }
    });
  }

  Future<void> _submit() async {
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(reservationControllerProvider.notifier).reserve(
            spaceId: widget.space.id,
            siteId: siteId,
            startTime: _start,
            endTime: _end,
            attendeeCount: int.tryParse(_attendeesController.text.trim()),
            purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
            inviteesNote: _inviteesController.text.trim().isEmpty ? null : _inviteesController.text.trim(),
            servicesNote: _servicesController.text.trim().isEmpty ? null : _servicesController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserved.')));
        _purposeController.clear();
        _attendeesController.clear();
        _inviteesController.clear();
        _servicesController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not reserve: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat.Hm();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reserve', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: true),
                    child: Text('Start ${timeFmt.format(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(isStart: false),
                    child: Text('End ${timeFmt.format(_end)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(labelText: 'Purpose (optional)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _attendeesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Attendee count (optional)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inviteesController,
              decoration: const InputDecoration(labelText: 'Invite (names, optional)', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _servicesController,
              decoration: const InputDecoration(labelText: 'Order services (optional)', isDense: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reserve'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _spaceProvider = FutureProvider.family<Space?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).locationDao.spaceById(id);
});

final _bookingsProvider = StreamProvider.family<List<Reservation>, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).reservationDao.watchForSpace(spaceId, DateTime.now());
});
