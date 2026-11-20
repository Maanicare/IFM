import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../location/presentation/current_site_provider.dart';
import 'visitor_controller.dart';

/// SCREEN 44 - Visitor Management (check in). Capture: Visitor; Host;
/// Company; Purpose; Arrival (auto, at submission); ID rules; Vehicle;
/// Access requirements.
class CheckInVisitorScreen extends ConsumerStatefulWidget {
  const CheckInVisitorScreen({super.key});

  @override
  ConsumerState<CheckInVisitorScreen> createState() => _CheckInVisitorScreenState();
}

class _CheckInVisitorScreenState extends ConsumerState<CheckInVisitorScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _hostController = TextEditingController();
  final _purposeController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _idTypeController = TextEditingController();
  final _accessController = TextEditingController();
  bool _idVerified = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _hostController.dispose();
    _purposeController.dispose();
    _vehicleController.dispose();
    _idTypeController.dispose();
    _accessController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final siteId = ref.read(currentSiteIdProvider).value;
    if (siteId == null) return;
    if (_nameController.text.trim().isEmpty || _hostController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor name and host are required.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final visitId = await ref.read(visitorControllerProvider.notifier).checkIn(
            siteId: siteId,
            visitorName: _nameController.text.trim(),
            visitorMobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
            visitorEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
            hostName: _hostController.text.trim(),
            purpose: _purposeController.text.trim().isEmpty ? null : _purposeController.text.trim(),
            vehicleNumber: _vehicleController.text.trim().isEmpty ? null : _vehicleController.text.trim(),
            idVerified: _idVerified,
            idTypeNote: _idTypeController.text.trim().isEmpty ? null : _idTypeController.text.trim(),
            accessRequirementsNote: _accessController.text.trim().isEmpty ? null : _accessController.text.trim(),
          );
      if (mounted) context.pushReplacement('/visitors/$visitId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not check in visitor: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check in visitor')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Visitor name (required)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host (required)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _purposeController,
              decoration: const InputDecoration(labelText: 'Purpose (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _vehicleController,
              decoration: const InputDecoration(labelText: 'Vehicle number (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _idVerified,
              title: const Text('ID verified'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _idVerified = v ?? false),
            ),
            TextField(
              controller: _idTypeController,
              decoration: const InputDecoration(labelText: 'ID type / number (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessController,
              decoration: const InputDecoration(labelText: 'Access requirements (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Check in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
