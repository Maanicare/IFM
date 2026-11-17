import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../attachments/presentation/attachment_capture_controller.dart';
import 'checklist_response_controller.dart';

/// Section C/D's checklist block (Section 35). Required items block
/// completion via [ChecklistDao.isComplete] - enforced by the caller
/// (Work Order Detail's completion button is still shown, but the
/// server will also reject an incomplete submission server-side).
class ChecklistSection extends ConsumerWidget {
  const ChecklistSection({super.key, required this.workOrderId, required this.checklistId});

  final String workOrderId;
  final String checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final itemsFuture = db.checklistDao.itemsFor(checklistId);
    final responses = ref.watch(_responsesProvider(workOrderId)).value ?? const [];
    final responseByItem = {for (final r in responses) r.itemId: r};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<List<ChecklistItem>>(
          future: itemsFuture,
          builder: (context, snapshot) {
            final items = snapshot.data ?? const [];
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Checklist', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final item in items)
                  _ChecklistItemRow(
                    workOrderId: workOrderId,
                    item: item,
                    existing: responseByItem[item.id],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _responsesProvider =
    StreamProvider.family<List<ChecklistResponse>, String>((ref, workOrderId) {
  final db = ref.watch(appDatabaseProvider);
  return db.checklistDao.watchResponsesFor(workOrderId);
});

class _ChecklistItemRow extends ConsumerWidget {
  const _ChecklistItemRow({required this.workOrderId, required this.item, this.existing});

  final String workOrderId;
  final ChecklistItem item;
  final ChecklistResponse? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(checklistResponseControllerProvider.notifier);
    final currentValue = existing != null
        ? (jsonDecode(existing!.responseJson) as Map<String, dynamic>)['value']
        : null;

    Widget input;
    switch (item.inputType) {
      case 'boolean':
        input = Row(
          children: [
            Expanded(child: Text(item.question)),
            Switch(
              value: currentValue == true,
              onChanged: (v) => controller.recordAnswer(
                workOrderId: workOrderId,
                itemId: item.id,
                value: v,
              ),
            ),
          ],
        );
        break;
      case 'number':
        input = _NumberField(
          question: item.question,
          initial: currentValue,
          min: item.minValue,
          max: item.maxValue,
          onChanged: (v) => controller.recordAnswer(
            workOrderId: workOrderId,
            itemId: item.id,
            value: v,
          ),
        );
        break;
      case 'photo':
      case 'signature':
        input = _EvidenceInput(
          workOrderId: workOrderId,
          item: item,
          currentPath: currentValue as String?,
        );
        break;
      default:
        input = Text(item.question);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            currentValue != null ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: currentValue != null ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(child: input),
          if (item.required)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('*', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

/// Photo/signature checklist items (Section 35, `input_type` photo |
/// signature). Captures through the device camera or an on-screen
/// signature pad, persists the file, and records an [Attachments] row
/// alongside the checklist response so the evidence survives
/// independently of the response's own lifecycle.
class _EvidenceInput extends ConsumerStatefulWidget {
  const _EvidenceInput({
    required this.workOrderId,
    required this.item,
    required this.currentPath,
  });

  final String workOrderId;
  final ChecklistItem item;
  final String? currentPath;

  @override
  ConsumerState<_EvidenceInput> createState() => _EvidenceInputState();
}

class _EvidenceInputState extends ConsumerState<_EvidenceInput> {
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    try {
      final attachmentController = ref.read(attachmentCaptureControllerProvider.notifier);
      final entityId = '${widget.workOrderId}:${widget.item.id}';

      final path = widget.item.inputType == 'photo'
          ? await attachmentController.capturePhoto(
              entityType: 'checklist_item',
              entityId: entityId,
              caption: widget.item.question,
            )
          : await attachmentController.captureSignature(
              context,
              entityType: 'checklist_item',
              entityId: entityId,
              title: widget.item.question,
            );

      if (path == null) return;
      await ref.read(checklistResponseControllerProvider.notifier).recordAnswer(
            workOrderId: widget.workOrderId,
            itemId: widget.item.id,
            value: path,
          );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhoto = widget.item.inputType == 'photo';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(widget.item.question)),
        if (widget.currentPath != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(widget.currentPath!),
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, size: 20),
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: _capturing
              ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(isPhoto ? Icons.camera_alt_outlined : Icons.draw_outlined),
          label: Text(widget.currentPath != null ? 'Retake' : 'Capture'),
          onPressed: _capturing ? null : _capture,
        ),
      ],
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({required this.question, this.initial, this.min, this.max, required this.onChanged});

  final String question;
  final Object? initial;
  final double? min;
  final double? max;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.question,
        helperText: (widget.min != null || widget.max != null)
            ? 'Range: ${widget.min ?? '-'} to ${widget.max ?? '-'}'
            : null,
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) widget.onChanged(parsed);
      },
    );
  }
}
