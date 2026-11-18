import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String _incidentType = 'near_miss';
  String _severity = 'low';
  String _hazardCategory = 'slip_trip_fall';
  int _riskProbability = 2;
  int _riskConsequence = 2;
  bool _injury = false;
  bool _submitting = false;

  static const _incidentTypes = ['injury', 'property_damage', 'fire', 'electrical', 'chemical_spill', 'near_miss', 'other'];
  static const _severities = ['low', 'medium', 'high', 'critical'];
  static const _hazardCategories = ['slip_trip_fall', 'electrical', 'fire', 'chemical', 'housekeeping', 'structural', 'other'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _immediateActionController.dispose();
    super.dispose();
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
        await controller.submitHazard(
          siteId: siteId,
          category: _hazardCategory,
          description: _descriptionController.text.trim(),
          riskProbability: _riskProbability,
          riskConsequence: _riskConsequence,
        );
      } else {
        await controller.submitIncident(
          siteId: siteId,
          type: _incidentType,
          severity: _severity,
          description: _descriptionController.text.trim(),
          injury: _injury,
          immediateAction: _immediateActionController.text.trim().isEmpty
              ? null
              : _immediateActionController.text.trim(),
        );
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
            ],
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
