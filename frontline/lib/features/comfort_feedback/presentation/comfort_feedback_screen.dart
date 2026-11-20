import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/presentation/current_site_provider.dart';
import '../domain/comfort_category.dart';
import 'comfort_feedback_controller.dart';

/// SCREEN 46 - Comfort Feedback. One-Touch: a tap submits immediately -
/// no form, no confirmation step - except "Other", which asks for a
/// short note since a bare "Other" tells nobody anything.
class ComfortFeedbackScreen extends ConsumerStatefulWidget {
  const ComfortFeedbackScreen({super.key});

  @override
  ConsumerState<ComfortFeedbackScreen> createState() => _ComfortFeedbackScreenState();
}

class _ComfortFeedbackScreenState extends ConsumerState<ComfortFeedbackScreen> {
  ComfortCategory? _justSubmitted;

  static const _icons = {
    ComfortCategory.tooHot: Icons.whatshot_outlined,
    ComfortCategory.tooCold: Icons.ac_unit_outlined,
    ComfortCategory.noise: Icons.volume_up_outlined,
    ComfortCategory.airQuality: Icons.air_outlined,
    ComfortCategory.lighting: Icons.lightbulb_outline,
    ComfortCategory.cleanliness: Icons.cleaning_services_outlined,
    ComfortCategory.other: Icons.more_horiz,
  };

  Future<void> _submit(ComfortCategory category, {String? note}) async {
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;
    try {
      await ref.read(comfortFeedbackControllerProvider.notifier).submit(
            siteId: siteId,
            category: category,
            note: note,
          );
      if (!mounted) return;
      setState(() => _justSubmitted = category);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanks - "${category.label}" feedback sent.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not send feedback: $e')));
    }
  }

  Future<void> _tapCategory(ComfortCategory category) async {
    if (category != ComfortCategory.other) {
      await _submit(category);
      return;
    }
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tell us more'),
        content: TextField(controller: controller, autofocus: true, maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (note != null && note.isNotEmpty) await _submit(category, note: note);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How is this space?')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          for (final category in ComfortCategory.values)
            _CategoryTile(
              icon: _icons[category]!,
              label: category.label,
              justSubmitted: _justSubmitted == category,
              onTap: () => _tapCategory(category),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.justSubmitted,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool justSubmitted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: justSubmitted ? Colors.green.shade50 : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(justSubmitted ? Icons.check_circle : icon, size: 32, color: justSubmitted ? Colors.green : null),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
