import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import 'shift_handover_controller.dart';

/// SCREEN 26 - Shift Handover (outgoing side). "Open jobs" is
/// auto-populated read-only from what's actually still open at the site
/// (Section 16.14: the point of a *digital* shift memory is that it
/// isn't reliant on the outgoing technician remembering to type it
/// themselves) - the rest are free-text briefing fields only the
/// outgoing team can know.
class CreateShiftHandoverScreen extends ConsumerStatefulWidget {
  const CreateShiftHandoverScreen({super.key, required this.siteId});

  final String siteId;

  @override
  ConsumerState<CreateShiftHandoverScreen> createState() => _CreateShiftHandoverScreenState();
}

class _CreateShiftHandoverScreenState extends ConsumerState<CreateShiftHandoverScreen> {
  final _equipmentIssue = TextEditingController();
  final _temporaryFix = TextEditingController();
  final _vendorExpected = TextEditingController();
  final _safetyConcern = TextEditingController();
  final _clientCommitment = TextEditingController();
  final _materialShortage = TextEditingController();
  final _specialInstruction = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [
      _equipmentIssue,
      _temporaryFix,
      _vendorExpected,
      _safetyConcern,
      _clientCommitment,
      _materialShortage,
      _specialInstruction,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(shiftHandoverControllerProvider.notifier).submitHandover(
            siteId: widget.siteId,
            openJobsNote: _openJobsSummary,
            equipmentIssueNote: _textOrNull(_equipmentIssue),
            temporaryFixNote: _textOrNull(_temporaryFix),
            vendorExpectedNote: _textOrNull(_vendorExpected),
            safetyConcernNote: _textOrNull(_safetyConcern),
            clientCommitmentNote: _textOrNull(_clientCommitment),
            materialShortageNote: _textOrNull(_materialShortage),
            specialInstructionNote: _textOrNull(_specialInstruction),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit handover: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _openJobsSummary;

  String? _textOrNull(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final openJobsAsync = ref.watch(_openJobsProvider(widget.siteId));

    return Scaffold(
      appBar: AppBar(title: const Text('New shift handover')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Open jobs', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            openJobsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load open jobs: $e'),
              data: (jobs) {
                _openJobsSummary = jobs.isEmpty
                    ? null
                    : jobs.map((w) => '${w.woNumber}: ${w.problemDescription ?? w.status}').join('\n');
                if (jobs.isEmpty) {
                  return const Text('No open jobs at this site.', style: TextStyle(color: Colors.grey));
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final w in jobs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• ${w.woNumber} — ${w.problemDescription ?? w.status}'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _Field(controller: _equipmentIssue, label: 'Equipment issue'),
            _Field(controller: _temporaryFix, label: 'Temporary fix in place'),
            _Field(controller: _vendorExpected, label: 'Vendor expected'),
            _Field(controller: _safetyConcern, label: 'Safety concern', isWarning: true),
            _Field(controller: _clientCommitment, label: 'Client commitment made'),
            _Field(controller: _materialShortage, label: 'Material shortage'),
            _Field(controller: _specialInstruction, label: 'Special instruction'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit handover'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.label, this.isWarning = false});

  final TextEditingController controller;
  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: isWarning ? const Icon(Icons.warning_amber, color: Colors.orange) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

final _openJobsProvider =
    FutureProvider.family<List<WorkOrder>, String>((ref, siteId) {
  return ref.watch(appDatabaseProvider).workOrderDao.openAtSite(siteId);
});
