import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/voice/voice_to_workflow_parser.dart';
import 'voice_note_controller.dart';

/// Section 16.12 (Frontline Voice-to-Workflow). The technician speaks a
/// free-form note; it's transcribed on-device, split into structured
/// fields by [VoiceToWorkflowParser], then shown back editable before
/// saving - the parser is a starting point, not an authority, matching
/// Section 53's "AI proposes, human confirms" boundary.
class VoiceNoteSection extends ConsumerStatefulWidget {
  const VoiceNoteSection({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  ConsumerState<VoiceNoteSection> createState() => _VoiceNoteSectionState();
}

class _VoiceNoteSectionState extends ConsumerState<VoiceNoteSection> {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  bool _initialized = false;
  String _transcript = '';
  VoiceWorkflowFields? _parsed;

  final _findingController = TextEditingController();
  final _readingController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _recommendationController = TextEditingController();

  @override
  void dispose() {
    _speech.stop();
    for (final c in [_findingController, _readingController, _diagnosisController, _recommendationController]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      _applyParse();
      return;
    }

    if (!_initialized) {
      _initialized = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
            _applyParse();
          }
        },
      );
    }
    if (!_initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available on this device.')),
        );
      }
      return;
    }

    setState(() {
      _listening = true;
      _transcript = '';
      _parsed = null;
    });
    await _speech.listen(
      onResult: (result) => setState(() => _transcript = result.recognizedWords),
    );
  }

  void _applyParse() {
    final parsed = VoiceToWorkflowParser.parse(_transcript);
    setState(() {
      _parsed = parsed;
      _findingController.text = parsed.finding ?? '';
      _readingController.text = parsed.reading ?? '';
      _diagnosisController.text = parsed.diagnosis ?? '';
      _recommendationController.text = parsed.recommendation ?? '';
    });
  }

  Future<void> _save() async {
    final fields = VoiceWorkflowFields(
      finding: _findingController.text.trim().isEmpty ? null : _findingController.text.trim(),
      reading: _readingController.text.trim().isEmpty ? null : _readingController.text.trim(),
      diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
      recommendation:
          _recommendationController.text.trim().isEmpty ? null : _recommendationController.text.trim(),
    );
    await ref.read(voiceNoteControllerProvider.notifier).saveFields(widget.workOrderId, fields);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice note saved.')));
      setState(() {
        _transcript = '';
        _parsed = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Voice note', style: Theme.of(context).textTheme.titleSmall)),
                IconButton.filledTonal(
                  icon: Icon(_listening ? Icons.stop : Icons.mic_none),
                  onPressed: _toggleListening,
                ),
              ],
            ),
            if (_listening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _transcript.isEmpty ? 'Listening...' : _transcript,
                  style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                ),
              ),
            if (_parsed != null && !_parsed!.isEmpty) ...[
              const SizedBox(height: 8),
              _EditableField(label: 'Finding', controller: _findingController),
              _EditableField(label: 'Reading', controller: _readingController),
              _EditableField(label: 'Diagnosis', controller: _diagnosisController),
              _EditableField(label: 'Recommendation', controller: _recommendationController),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: _save, child: const Text('Save voice note')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}
