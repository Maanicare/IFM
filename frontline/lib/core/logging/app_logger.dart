import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'log_entry.dart';

/// Structured, file-backed logger.
///
/// Every call appends one NDJSON (newline-delimited JSON) line to a rolling
/// log file inside the application-support directory. NDJSON is used
/// (instead of a single JSON array) because:
///   - it survives abrupt process death (each line is already complete),
///   - it can be appended to cheaply without re-parsing the whole file,
///   - it is trivially exportable/diffable for support tickets.
///
/// The file rolls over once it exceeds [_maxFileBytes] to keep disk usage
/// and export size bounded on long-lived field devices.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const String _baseFileName = 'onemaanicare_frontline.log.ndjson';
  static const int _maxFileBytes = 5 * 1024 * 1024; // 5 MB per file
  static const int _maxRolledFiles = 3;

  File? _file;
  final _writeLock = _AsyncLock();

  Future<File> _ensureFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    final logsDir = Directory('${dir.path}/logs');
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    _file = File('${logsDir.path}/$_baseFileName');
    if (!await _file!.exists()) {
      await _file!.create(recursive: true);
    }
    return _file!;
  }

  Future<void> _write(LogEntry entry) async {
    await _writeLock.synchronized(() async {
      final file = await _ensureFile();
      await _rollIfNeeded(file);
      await file.writeAsString(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
    });
  }

  Future<void> _rollIfNeeded(File file) async {
    if (!await file.exists()) return;
    final length = await file.length();
    if (length < _maxFileBytes) return;

    final dir = file.parent;
    // Shift existing rolled files up by one index, dropping the oldest.
    for (var i = _maxRolledFiles - 1; i >= 1; i--) {
      final src = File('${dir.path}/$_baseFileName.$i');
      final dst = File('${dir.path}/$_baseFileName.${i + 1}');
      if (await src.exists()) {
        if (i + 1 > _maxRolledFiles) {
          await src.delete();
        } else {
          await src.rename(dst.path);
        }
      }
    }
    await file.rename('${dir.path}/$_baseFileName.1');
    _file = File(file.path)..createSync(recursive: true);
  }

  void debug(String tag, String message, {Map<String, Object?>? context}) =>
      unawaited(_write(LogEntry(
        timestamp: DateTime.now(),
        level: 'debug',
        tag: tag,
        message: message,
        context: context,
      )));

  void info(String tag, String message, {Map<String, Object?>? context}) =>
      unawaited(_write(LogEntry(
        timestamp: DateTime.now(),
        level: 'info',
        tag: tag,
        message: message,
        context: context,
      )));

  void warning(String tag, String message, {Map<String, Object?>? context}) =>
      unawaited(_write(LogEntry(
        timestamp: DateTime.now(),
        level: 'warning',
        tag: tag,
        message: message,
        context: context,
      )));

  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      unawaited(_write(LogEntry(
        timestamp: DateTime.now(),
        level: 'error',
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      )));

  void fatal(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) =>
      unawaited(_write(LogEntry(
        timestamp: DateTime.now(),
        level: 'fatal',
        tag: tag,
        message: message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      )));

  /// Gathers the active log file plus any rolled-over files into one list,
  /// suitable for attaching to a support diagnostics export.
  Future<List<File>> collectLogFiles() async {
    final file = await _ensureFile();
    final dir = file.parent;
    final files = <File>[file];
    for (var i = 1; i <= _maxRolledFiles; i++) {
      final rolled = File('${dir.path}/$_baseFileName.$i');
      if (await rolled.exists()) files.add(rolled);
    }
    return files;
  }

  /// Opens the OS share sheet with all current log files attached, so a
  /// frontline user (or supervisor) can send diagnostics to support without
  /// needing device access or a tethered debugger.
  Future<void> shareDiagnostics({String? subject}) async {
    final files = await collectLogFiles();
    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path)],
        subject: subject ?? 'OneMaanicare — Diagnostics Export',
      ),
    );
  }
}

/// Minimal mutual-exclusion lock so concurrent log calls don't interleave
/// writes to the same file.
class _AsyncLock {
  Future<void>? _current;

  Future<T> synchronized<T>(Future<T> Function() action) async {
    final previous = _current;
    final completer = Completer<void>();
    _current = completer.future;
    if (previous != null) await previous;
    try {
      return await action();
    } finally {
      completer.complete();
    }
  }
}
