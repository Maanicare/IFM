import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../util/id_generator.dart';

/// Captures evidence files (photos, signatures) to local app storage so
/// the rest of the capture-to-sync pipeline (an [Attachments] row, then
/// the outbox) always deals with a durable local path - never an
/// in-memory value that would be lost if the app is killed mid-capture
/// (Section 3.2: evidence before claims).
class EvidenceCapture {
  const EvidenceCapture._();

  /// Opens the device camera and saves the photo under the app's
  /// documents directory. Returns null if the technician cancels.
  static Future<String?> capturePhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _persist(await picked.readAsBytes(), extension: 'jpg');
  }

  /// Shows a full-screen signature pad and saves the result as a PNG.
  /// Returns null if the technician cancels without drawing anything.
  static Future<String?> captureSignature(
    BuildContext context, {
    String title = 'Sign here',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => _SignatureDialog(title: title),
    );
  }

  static Future<String> _persist(List<int> bytes, {required String extension}) async {
    final dir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(dir.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    final filePath = p.join(attachmentsDir.path, '${IdGenerator.newId()}.$extension');
    await File(filePath).writeAsBytes(bytes, flush: true);
    return filePath;
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog({required this.title});
  final String title;

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final bytes = await _controller.toPngBytes();
    if (bytes == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final path = await EvidenceCapture._persist(bytes, extension: 'png');
    if (mounted) Navigator.of(context).pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Signature(controller: _controller, backgroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => _controller.clear(),
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
