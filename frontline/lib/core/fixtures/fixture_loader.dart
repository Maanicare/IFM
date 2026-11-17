import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled demo JSON fixtures used by every `Mock*Repository`.
///
/// Fixtures encode SLA-sensitive timestamps as `*OffsetMinutes` relative to
/// "now" (e.g. `slaResolutionOffsetMinutes: -5` means "5 minutes overdue"),
/// rather than baked-in absolute dates, so the overdue-SLA and upcoming-SLA
/// demo scenarios stay realistic no matter when the app is actually run.
/// [resolveOffsets] walks a decoded JSON map and converts every
/// `*OffsetMinutes` key into the corresponding absolute ISO-8601 key.
class FixtureLoader {
  const FixtureLoader._();

  static Future<dynamic> loadJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return jsonDecode(raw);
  }

  /// Returns a copy of [record] where every key ending in `OffsetMinutes`
  /// is replaced by a `now + offset` [DateTime] under the same key with
  /// that suffix stripped (e.g. `slaResolutionOffsetMinutes` -> becomes
  /// available to callers as `resolveAt('slaResolution', record)`).
  static DateTime? resolveOffset(Map<String, dynamic> record, String field) {
    final key = '${field}OffsetMinutes';
    final offset = record[key];
    if (offset == null) return null;
    return DateTime.now().add(Duration(minutes: (offset as num).toInt()));
  }
}
