/// Converts a transcribed technician voice note into structured fields
/// (Section 16.12: "Motor bearing is noisy, temperature is 78 degrees,
/// belt is fine, recommend bearing replacement" -> Finding, Reading,
/// Diagnosis, Recommendation).
///
/// This is a deliberately simple keyword-based splitter, not an LLM -
/// the spec's AI architecture principles (Section 53) keep AI as a
/// proposal layer the technician reviews/edits before it's saved, which
/// is exactly what the editable fields in [VoiceNoteSection] provide
/// regardless of how good the initial split is.
class VoiceWorkflowFields {
  const VoiceWorkflowFields({this.finding, this.reading, this.diagnosis, this.recommendation});

  final String? finding;
  final String? reading;
  final String? diagnosis;
  final String? recommendation;

  bool get isEmpty =>
      finding == null && reading == null && diagnosis == null && recommendation == null;
}

class VoiceToWorkflowParser {
  const VoiceToWorkflowParser._();

  static final _recommendationMarkers = ['recommend', 'suggest', 'should replace', 'needs'];
  static final _readingMarkers = ['degrees', 'reading is', 'temperature is', 'pressure is', 'rpm'];
  static final _diagnosisMarkers = ['diagnosis', 'likely', 'appears to be', 'caused by', 'due to'];

  static VoiceWorkflowFields parse(String transcript) {
    if (transcript.trim().isEmpty) return const VoiceWorkflowFields();

    final sentences = transcript
        .split(RegExp(r'[.,;]\s*|\s+and\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    String? finding;
    String? reading;
    String? diagnosis;
    String? recommendation;

    for (final sentence in sentences) {
      final lower = sentence.toLowerCase();
      if (_recommendationMarkers.any(lower.contains)) {
        recommendation = _appendOrSet(recommendation, sentence);
      } else if (_readingMarkers.any(lower.contains)) {
        reading = _appendOrSet(reading, sentence);
      } else if (_diagnosisMarkers.any(lower.contains)) {
        diagnosis = _appendOrSet(diagnosis, sentence);
      } else {
        // Default bucket: an unmarked observation is treated as a
        // finding (Section 16.12's own example leads with one).
        finding = _appendOrSet(finding, sentence);
      }
    }

    return VoiceWorkflowFields(
      finding: finding,
      reading: reading,
      diagnosis: diagnosis,
      recommendation: recommendation,
    );
  }

  static String _appendOrSet(String? existing, String addition) {
    if (existing == null || existing.isEmpty) return addition;
    return '$existing. $addition';
  }
}
