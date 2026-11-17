import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/media/evidence_capture.dart';
import '../../location/presentation/current_site_provider.dart';
import 'request_controller.dart';

/// SCREEN 06 - Create Request. Required: category, description,
/// location. Optional: asset, photo, affected people, safety concern
/// (Smart Behaviour - AI category suggestion/duplicate detection - is a
/// server-side concern out of scope for this screen).
class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key, this.initialAssetId, this.initialSpaceId});

  final String? initialAssetId;
  final String? initialSpaceId;

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _affectedPeopleController = TextEditingController();
  String _category = 'general';
  String _priority = 'medium';
  String? _spaceId;
  bool _safetyConcern = false;
  bool _submitting = false;
  final List<String> _photoPaths = [];

  static const _categories = ['hvac', 'electrical', 'plumbing', 'housekeeping', 'general'];
  static const _priorities = ['low', 'medium', 'high', 'critical'];

  @override
  void initState() {
    super.initState();
    _spaceId = widget.initialSpaceId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _affectedPeopleController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    final path = await EvidenceCapture.capturePhoto();
    if (path != null) setState(() => _photoPaths.add(path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Uses the technician's currently-selected site (Screen 02), not
    // always the first assigned one - a multi-site user who has switched
    // must have the request land against the site they're actually at.
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;
    if (_spaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final requestId = await ref.read(requestControllerProvider.notifier).createRequest(
            siteId: siteId,
            spaceId: _spaceId,
            assetId: widget.initialAssetId,
            categoryId: _category,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            priority: _priority,
            affectedPeopleCount: int.tryParse(_affectedPeopleController.text.trim()),
            safetyConcern: _safetyConcern,
            photoPaths: _photoPaths,
          );
      if (!mounted) return;
      // Replace (not push) this form with the detail screen - back from
      // the detail should return to wherever the form itself was opened
      // from, not re-show the now-submitted form.
      context.pushReplacement('/requests/$requestId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create request: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.initialAssetId != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.link, size: 16),
                      SizedBox(width: 6),
                      Text('Linked to scanned asset'),
                    ],
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),
              if (siteId != null) _SpacePicker(
                siteId: siteId,
                value: _spaceId,
                onChanged: (v) => setState(() => _spaceId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'What\'s the issue?'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Urgency'),
                items: _priorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _affectedPeopleController,
                decoration: const InputDecoration(labelText: 'Affected people (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _safetyConcern,
                onChanged: (v) => setState(() => _safetyConcern = v ?? false),
                title: const Text('This is a safety concern'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in _photoPaths)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(path), width: 64, height: 64, fit: BoxFit.cover),
                    ),
                  InkWell(
                    onTap: _addPhoto,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpacePicker extends ConsumerWidget {
  const _SpacePicker({required this.siteId, required this.value, required this.onChanged});

  final String siteId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesAsync = ref.watch(_spacesForSiteProvider(siteId));
    final spaces = spacesAsync.value ?? const [];

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Location'),
      items: spaces
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Required' : null,
    );
  }
}

final _spacesForSiteProvider = FutureProvider.family<List<Space>, String>((ref, siteId) async {
  final db = ref.watch(appDatabaseProvider);
  final buildings = await db.locationDao.buildingsForSite(siteId);
  final spaces = <Space>[];
  for (final building in buildings) {
    final floors = await db.locationDao.floorsForBuilding(building.id);
    for (final floor in floors) {
      spaces.addAll(await db.locationDao.spacesForFloor(floor.id));
    }
  }
  return spaces;
});
