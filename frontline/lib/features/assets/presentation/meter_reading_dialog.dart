import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import 'meter_reading_controller.dart';

/// Captures a meter reading in the field (Section 33; Screen 12
/// "Operational" / Screen 09 "Execution: Readings"). Shared between the
/// Asset Profile screen (standalone reading) and Work Order Detail
/// (reading tied to the job) - the only difference is whether
/// [workOrderId] is passed through.
Future<void> showMeterReadingDialog(
  BuildContext context,
  WidgetRef ref, {
  required AssetMeter meter,
  String? workOrderId,
}) async {
  final controller = TextEditingController(text: meter.currentValue?.toString() ?? '');
  final value = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Record ${meter.meterType.replaceAll('_', ' ')}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Reading (${meter.unit})',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final parsed = double.tryParse(controller.text);
            Navigator.of(context).pop(parsed);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (value == null) return;

  await ref.read(meterReadingControllerProvider.notifier).recordReading(
        meterId: meter.id,
        value: value,
        workOrderId: workOrderId,
      );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reading saved: $value ${meter.unit}')),
    );
  }
}
