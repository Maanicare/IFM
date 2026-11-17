/// A single structured log line written to the rolling NDJSON log file.
///
/// Kept deliberately simple (no code generation) since it is written to disk
/// extremely frequently and must serialise cheaply and deterministically.
class LogEntry {
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
    this.context,
  });

  final DateTime timestamp;
  final String level; // debug | info | warning | error | fatal
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?>? context;

  /// One compact JSON object per line (NDJSON) so the log file can be
  /// streamed/tailed and parsed line-by-line without loading the whole file.
  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'level': level,
        'tag': tag,
        'message': message,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
        if (context != null && context!.isNotEmpty) 'context': context,
      };
}
