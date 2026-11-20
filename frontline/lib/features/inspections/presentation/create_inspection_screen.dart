import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/media/evidence_capture.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/util/id_generator.dart';
import '../../location/presentation/current_site_provider.dart';
import '../domain/soft_service_template.dart';
import 'inspection_controller.dart';

/// SCREEN 23 - Soft Service Inspection (record a new one).
class CreateInspectionScreen extends ConsumerStatefulWidget {
  const CreateInspectionScreen({super.key});

  @override
  ConsumerState<CreateInspectionScreen> createState() => _CreateInspectionScreenState();
}

class _CreateInspectionScreenState extends ConsumerState<CreateInspectionScreen> {
  SoftServiceTemplate _template = SoftServiceTemplate.housekeeping;
  double _score = 80;
  final _nonConformanceController = TextEditingController();
  final _correctiveTaskController = TextEditingController();
  final _correctiveOwnerController = TextEditingController();
  DateTime? _correctiveDueDate;
  String? _photoPath;
  bool _submitting = false;

  @override
  void dispose() {
    _nonConformanceController.dispose();
    _correctiveTaskController.dispose();
    _correctiveOwnerController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final path = await EvidenceCapture.capturePhoto();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _correctiveDueDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _correctiveDueDate = picked);
  }

  Future<void> _submit() async {
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;

    setState(() => _submitting = true);
    try {
      final inspectionId = await ref.read(inspectionControllerProvider.notifier).submitInspection(
            siteId: siteId,
            template: _template,
            score: _score,
            nonConformanceNote: _nonConformanceController.text.trim().isEmpty
                ? null
                : _nonConformanceController.text.trim(),
            correctiveTaskNote: _correctiveTaskController.text.trim().isEmpty
                ? null
                : _correctiveTaskController.text.trim(),
            correctiveOwnerName: _correctiveOwnerController.text.trim().isEmpty
                ? null
                : _correctiveOwnerController.text.trim(),
            correctiveDueDate: _correctiveDueDate,
          );

      if (_photoPath != null) {
        final userId = ref.read(currentAccessContextProvider)?.userId;
        if (userId != null) {
          final db = ref.read(appDatabaseProvider);
          await db.attachmentDao.add(AttachmentsCompanion.insert(
            id: IdGenerator.newId(),
            entityType: 'soft_service_inspection',
            entityId: inspectionId,
            fileType: 'photo',
            localPath: _photoPath!,
            uploadedBy: userId,
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspection recorded.')),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not record inspection: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New inspection')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<SoftServiceTemplate>(
              initialValue: _template,
              decoration: const InputDecoration(labelText: 'Template'),
              items: SoftServiceTemplate.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _template = v ?? _template),
            ),
            const SizedBox(height: 16),
            Text('Score: ${_score.toStringAsFixed(0)}'),
            Slider(
              value: _score,
              min: 0,
              max: 100,
              divisions: 20,
              label: _score.toStringAsFixed(0),
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nonConformanceController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Non-conformance (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _capturePhoto,
              icon: Icon(_photoPath != null ? Icons.check_circle : Icons.camera_alt_outlined),
              label: Text(_photoPath != null ? 'Photo added' : 'Add photo'),
            ),
            const Divider(height: 32),
            Text('Corrective action', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _correctiveTaskController,
              decoration: const InputDecoration(
                labelText: 'Corrective task (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _correctiveOwnerController,
              decoration: const InputDecoration(
                labelText: 'Owner (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(
                _correctiveDueDate != null
                    ? 'Due ${DateFormat.yMMMd().format(_correctiveDueDate!)}'
                    : 'Set due date (optional)',
              ),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit inspection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
