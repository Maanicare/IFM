import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/media/evidence_capture.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/util/id_generator.dart';
import '../domain/permit_type.dart';
import 'permit_controller.dart';

/// SCREEN 37 - Permit to Work (issue a new one).
class CreatePermitScreen extends ConsumerStatefulWidget {
  const CreatePermitScreen({super.key, required this.siteId, this.workOrderId});

  final String siteId;
  final String? workOrderId;

  @override
  ConsumerState<CreatePermitScreen> createState() => _CreatePermitScreenState();
}

class _CreatePermitScreenState extends ConsumerState<CreatePermitScreen> {
  PermitType _type = PermitType.hotWork;
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(const Duration(hours: 8));
  final _vendorController = TextEditingController();
  final _riskAssessmentController = TextEditingController();
  final _authorisedPersonsController = TextEditingController();
  final _controlsController = TextEditingController();
  final _isolationController = TextEditingController();
  final _issuerController = TextEditingController();
  final _receiverController = TextEditingController();
  String? _photoPath;
  bool _submitting = false;

  @override
  void dispose() {
    _vendorController.dispose();
    _riskAssessmentController.dispose();
    _authorisedPersonsController.dispose();
    _controlsController.dispose();
    _isolationController.dispose();
    _issuerController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final initial = isFrom ? _validFrom : _validTo;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _validFrom = combined;
      } else {
        _validTo = combined;
      }
    });
  }

  Future<void> _capturePhoto() async {
    final path = await EvidenceCapture.capturePhoto();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _submit() async {
    if (_issuerController.text.trim().isEmpty || _receiverController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Issuer and receiver are required.')),
      );
      return;
    }
    if (!_validTo.isAfter(_validFrom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valid-to must be after valid-from.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final permitId = await ref.read(permitControllerProvider.notifier).issuePermit(
            siteId: widget.siteId,
            workOrderId: widget.workOrderId,
            type: _type,
            vendorName: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
            validFrom: _validFrom,
            validTo: _validTo,
            riskAssessmentNote:
                _riskAssessmentController.text.trim().isEmpty ? null : _riskAssessmentController.text.trim(),
            authorisedPersons:
                _authorisedPersonsController.text.trim().isEmpty ? null : _authorisedPersonsController.text.trim(),
            controlsNote: _controlsController.text.trim().isEmpty ? null : _controlsController.text.trim(),
            isolationNote: _isolationController.text.trim().isEmpty ? null : _isolationController.text.trim(),
            issuerName: _issuerController.text.trim(),
            receiverName: _receiverController.text.trim(),
          );

      if (_photoPath != null) {
        final userId = ref.read(currentAccessContextProvider)?.userId;
        if (userId != null) {
          final db = ref.read(appDatabaseProvider);
          await db.attachmentDao.add(AttachmentsCompanion.insert(
            id: IdGenerator.newId(),
            entityType: 'permit',
            entityId: permitId,
            fileType: 'photo',
            localPath: _photoPath!,
            caption: const Value('Risk assessment'),
            uploadedBy: userId,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permit issued.')));
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not issue permit: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: const Text('Issue permit')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<PermitType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: PermitType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_circle_outline),
              title: Text('Start: ${fmt.format(_validFrom)}'),
              onTap: () => _pickDateTime(isFrom: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_circle_outlined),
              title: Text('End: ${fmt.format(_validTo)}'),
              onTap: () => _pickDateTime(isFrom: false),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _issuerController,
              decoration: const InputDecoration(labelText: 'Issuer (required)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receiverController,
              decoration: const InputDecoration(labelText: 'Receiver / authorised worker (required)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorisedPersonsController,
              decoration: const InputDecoration(labelText: 'Other authorised persons (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: 'Vendor (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _riskAssessmentController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Risk assessment (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _capturePhoto,
              icon: Icon(_photoPath != null ? Icons.check_circle : Icons.camera_alt_outlined),
              label: Text(_photoPath != null ? 'Risk assessment photo added' : 'Add risk assessment photo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controlsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Controls (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _isolationController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Isolation (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Issue permit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
