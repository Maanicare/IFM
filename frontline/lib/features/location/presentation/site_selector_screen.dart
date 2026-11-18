import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import 'current_site_provider.dart';
import 'site_switch_controller.dart';

/// SCREEN 02 - Role/Site Selector. Only meaningful for a user assigned to
/// more than one site (Section 6: a Regional Head or multi-site
/// Technician); shown as an explicit screen rather than a silent default
/// so switching is always a deliberate, visible action - a technician
/// should never submit a job update against the wrong site because a
/// stale selection carried over unnoticed.
class SiteSelectorScreen extends ConsumerWidget {
  const SiteSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final currentSiteId = ref.watch(currentSiteIdProvider).value;
    final recentIds = ref.watch(_recentSiteIdsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Select site')),
      body: user == null
          ? const SizedBox.shrink()
          : FutureBuilder<List<Site>>(
              future: ref.read(appDatabaseProvider).locationDao.sitesByIds(user.siteIds),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sites = snapshot.data!;
                if (sites.isEmpty) {
                  return const Center(child: Text('No sites assigned to your account.'));
                }

                // Recent site(s) - excludes whatever is current, since
                // "recent" means "where I was before this" (Screen 02).
                final recentSites = [
                  for (final id in recentIds)
                    if (id != currentSiteId)
                      ...sites.where((s) => s.id == id),
                ];

                // Portfolio -> Region -> sites, in that order, matching
                // the Display order the spec lists them in.
                final byPortfolio = <String, Map<String, List<Site>>>{};
                for (final site in sites) {
                  final portfolio = site.portfolioName ?? 'Unassigned portfolio';
                  final region = site.region ?? 'Unassigned region';
                  byPortfolio.putIfAbsent(portfolio, () => {});
                  byPortfolio[portfolio]!.putIfAbsent(region, () => []).add(site);
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (recentSites.isNotEmpty) ...[
                      const _SectionLabel('Recent'),
                      for (final site in recentSites)
                        _SiteTile(site: site, isCurrent: false),
                      const SizedBox(height: 12),
                    ],
                    for (final portfolioEntry in byPortfolio.entries) ...[
                      _SectionLabel(portfolioEntry.key),
                      for (final regionEntry in portfolioEntry.value.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            regionEntry.key,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        for (final site in regionEntry.value)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SiteTile(site: site, isCurrent: site.id == currentSiteId),
                          ),
                      ],
                    ],
                  ],
                );
              },
            ),
    );
  }
}

final _recentSiteIdsProvider = StreamProvider<List<String>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.identityDao.watchCurrentUser().map((cached) {
    if (cached == null) return const <String>[];
    return (jsonDecode(cached.recentSiteIdsJson) as List).cast<String>();
  });
});

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SiteTile extends ConsumerStatefulWidget {
  const _SiteTile({required this.site, required this.isCurrent});

  final Site site;
  final bool isCurrent;

  @override
  ConsumerState<_SiteTile> createState() => _SiteTileState();
}

class _SiteTileState extends ConsumerState<_SiteTile> {
  bool _busy = false;

  Future<void> _switch() async {
    if (widget.isCurrent) return;
    setState(() => _busy = true);
    try {
      await ref.read(siteSwitchControllerProvider.notifier).switchTo(widget.site.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Switched to ${widget.site.name}.')),
        );
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch site: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Screen 02's second action: "Set default" - independent of
  /// switching, so confirming a default doesn't disrupt whatever the
  /// technician is currently looking at.
  Future<void> _setDefault() async {
    await ref.read(siteSwitchControllerProvider.notifier).setDefault(widget.site.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.site.name} set as your default site.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final isActive = site.operationalStatus == 'active';

    return Card(
      color: widget.isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: _busy ? null : _switch,
        leading: Icon(
          widget.isCurrent ? Icons.check_circle : Icons.apartment_outlined,
          color: widget.isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(site.name),
        subtitle: Text('${site.code} · ${isActive ? 'Operational' : site.operationalStatus}'),
        trailing: _busy
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Set as default',
                    icon: const Icon(Icons.push_pin_outlined, size: 20),
                    onPressed: _setDefault,
                  ),
                  if (widget.isCurrent)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('Current', style: TextStyle(fontWeight: FontWeight.w600)),
                    )
                  else
                    const Icon(Icons.chevron_right),
                ],
              ),
      ),
    );
  }
}
