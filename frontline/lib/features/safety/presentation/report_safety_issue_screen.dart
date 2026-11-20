import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/media/evidence_capture.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/util/id_generator.dart';
import '../../location/presentation/current_site_provider.dart';
import 'safety_report_controller.dart';

/// SCREEN 35/36 - Incident Report / Hazard & Near Miss. One entry point
/// with a type toggle rather than two separate screens - a Security
/// Supervisor deciding what they just saw shouldn't have to pick the
/// right screen before they can even start describing it.
class ReportSafetyIssueScreen extends ConsumerStatefulWidget {
  const ReportSafetyIssueScreen({super.key});

  @override
  ConsumerState<ReportSafetyIssueScreen> createState() => _ReportSafetyIssueScreenState();
}

class _ReportSafetyIssueScreenState extends ConsumerState<ReportSafetyIssueScreen> {
  bool _isHazard = false;
  final _descriptionController = TextEditingController();
  final _immediateActionController = TextEditingController();
  final _peopleInvolvedController = TextEditingController();
  final _witnessesController = TextEditingController();
  String _incidentType = 'near_miss';
  String _severity = 'low';
  String _hazardCategory = 'slip_trip_fall';
  int _riskProbability = 2;
  int _riskConsequence = 2;
  bool _injury = false;
  bool _submitting = false;
  String? _spaceId;
  String? _assetId;
  String? _photoPath;
  String? _voiceNotePath;

  static const _incidentTypes = ['injury', 'property_damage', 'fire', 'electrical', 'chemical_spill', 'near_miss', 'other'];
  static const _severities = ['low', 'medium', 'high', 'critical'];
  static const _hazardCategories = ['slip_trip_fall', 'electrical', 'fire', 'chemical', 'housekeeping', 'structural', 'other'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _immediateActionController.dispose();
    _peopleInvolvedController.dispose();
    _witnessesController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    final path = await EvidenceCapture.capturePhoto();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _recordVoiceNote() async {
    final path = await EvidenceCapture.captureVoiceNote(context);
    if (path != null) setState(() => _voiceNotePath = path);
  }

  Future<void> _saveEvidence(String entityType, String entityId) async {
    final db = ref.read(appDatabaseProvider);
    final userId = ref.read(currentAccessContextProvider)?.userId;
    if (userId == null) return;
    Future<void> save(String path, String fileType) {
      return db.attachmentDao.add(AttachmentsCompanion.insert(
        id: IdGenerator.newId(),
        entityType: entityType,
        entityId: entityId,
        fileType: fileType,
        localPath: path,
        uploadedBy: userId,
        createdAt: DateTime.now(),
      ));
    }

    if (_photoPath != null) await save(_photoPath!, 'photo');
    if (_voiceNotePath != null) await save(_voiceNotePath!, 'voice');
  }

  Future<void> _submit() async {
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what happened.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final controller = ref.read(safetyReportControllerProvider.notifier);
      if (_isHazard) {
        final hazardId = await controller.submitHazard(
          siteId: siteId,
          spaceId: _spaceId,
          category: _hazardCategory,
          description: _descriptionController.text.trim(),
          riskProbability: _riskProbability,
          riskConsequence: _riskConsequence,
        );
        await _saveEvidence('hazard', hazardId);
      } else {
        final incidentId = await controller.submitIncident(
          siteId: siteId,
          spaceId: _spaceId,
          type: _incidentType,
          severity: _severity,
          description: _descriptionController.text.trim(),
          assetId: _assetId,
          injury: _injury,
          immediateAction: _immediateActionController.text.trim().isEmpty
              ? null
              : _immediateActionController.text.trim(),
          peopleInvolved: _peopleInvolvedController.text.trim().isEmpty
              ? null
              : _peopleInvolvedController.text.trim(),
          witnesses: _witnessesController.text.trim().isEmpty
              ? null
              : _witnessesController.text.trim(),
        );
        await _saveEvidence('incident', incidentId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isHazard ? 'Hazard reported.' : 'Incident reported.')),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit report: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskScore = _riskProbability * _riskConsequence;
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Safety Issue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Incident'), icon: Icon(Icons.report_outlined)),
                ButtonSegment(value: true, label: Text('Hazard / Near Miss'), icon: Icon(Icons.warning_amber_outlined)),
              ],
              selected: {_isHazard},
              onSelectionChanged: (s) => setState(() => _isHazard = s.first),
            ),
            const SizedBox(height: 16),
            if (siteId != null) _SpacePicker(siteId: siteId, value: _spaceId, onChanged: (v) => setState(() => _spaceId = v)),
            const SizedBox(height: 12),
            if (!_isHazard) ...[
              DropdownButtonFormField<String>(
                initialValue: _incidentType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _incidentTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setState(() => _incidentType = v ?? _incidentType),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: const InputDecoration(labelText: 'Severity'),
                items: _severities.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 12),
              if (siteId != null) _AssetPicker(siteId: siteId, value: _assetId, onChanged: (v) => setState(() => _assetId = v)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _injury,
                title: const Text('Injury involved'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _injury = v ?? false),
              ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: _hazardCategory,
                decoration: const InputDecoration(labelText: 'Hazard type'),
                items: _hazardCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ')))).toList(),
                onChanged: (v) => setState(() => _hazardCategory = v ?? _hazardCategory),
              ),
              const SizedBox(height: 12),
              Text('Probability: $_riskProbability'),
              Slider(
                value: _riskProbability.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_riskProbability',
                onChanged: (v) => setState(() => _riskProbability = v.round()),
              ),
              Text('Consequence: $_riskConsequence'),
              Slider(
                value: _riskConsequence.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_riskConsequence',
                onChanged: (v) => setState(() => _riskConsequence = v.round()),
              ),
              Text('Risk score: $riskScore', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What happened?', border: OutlineInputBorder()),
            ),
            if (!_isHazard) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _immediateActionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Immediate action taken (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _peopleInvolvedController,
                decoration: const InputDecoration(labelText: 'People involved (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _witnessesController,
                decoration: const InputDecoration(labelText: 'Witnesses (optional)', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _capturePhoto,
                    icon: Icon(_photoPath != null ? Icons.check_circle : Icons.camera_alt_outlined),
                    label: Text(_photoPath != null ? 'Photo added' : 'Add photo'),
                  ),
                ),
                if (_isHazard) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _recordVoiceNote,
                      icon: Icon(_voiceNotePath != null ? Icons.check_circle : Icons.mic_none),
                      label: Text(_voiceNotePath != null ? 'Voice added' : 'Add voice'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screens 35/36 "Location" - a specific space at the current site, not
/// just the site itself.
class _SpacePicker extends ConsumerWidget {
  const _SpacePicker({required this.siteId, required this.value, required this.onChanged});
  final String siteId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(_spacesProvider(siteId)).value ?? const [];
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Location (optional)'),
      items: [
        for (final space in spaces) DropdownMenuItem(value: space.id, child: Text(space.name)),
      ],
      onChanged: onChanged,
    );
  }
}

/// Screen 35 "Asset" - optionally link the incident to a specific asset
/// at the site.
class _AssetPicker extends ConsumerWidget {
  const _AssetPicker({required this.siteId, required this.value, required this.onChanged});
  final String siteId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(_assetsProvider(siteId)).value ?? const [];
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Asset (optional)'),
      items: [
        for (final asset in assets) DropdownMenuItem(value: asset.id, child: Text(asset.name)),
      ],
      onChanged: onChanged,
    );
  }
}

final _spacesProvider = FutureProvider.family<List<Space>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).locationDao.searchSpacesAtSite(siteId, '');
});

final _assetsProvider = FutureProvider.family<List<Asset>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).assetDao.forSite(siteId);
});
