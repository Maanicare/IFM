import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/fixtures/fixture_loader.dart';

part 'client_branding.g.dart';

/// Screen 01: "client branding if configured". Placeholder lookup by
/// the identifier's email domain - a real implementation would resolve
/// this server-side (the organisation a user belongs to, not just
/// their domain), but this gives the login screen a working "if
/// configured, show it" path rather than nothing at all.
class ClientBranding {
  const ClientBranding({required this.name, required this.color});
  final String name;
  final Color color;
}

@riverpod
Future<ClientBranding?> clientBranding(Ref ref, String identifier) async {
  final domain = identifier.contains('@') ? identifier.split('@').last.toLowerCase() : null;
  if (domain == null) return null;

  final list = await FixtureLoader.loadJson('assets/fixtures/client_branding.json') as List;
  for (final entry in list.cast<Map<String, dynamic>>()) {
    if ((entry['domain'] as String).toLowerCase() == domain) {
      final colorHex = (entry['color'] as String).replaceFirst('#', '');
      return ClientBranding(
        name: entry['name'] as String,
        color: Color(int.parse('FF$colorHex', radix: 16)),
      );
    }
  }
  return null;
}
