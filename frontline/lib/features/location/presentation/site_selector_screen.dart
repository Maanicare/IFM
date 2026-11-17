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
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _SiteTile(site: sites[index], isCurrent: sites[index].id == currentSiteId),
                );
              },
            ),
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
  bool _switching = false;

  Future<void> _select() async {
    if (widget.isCurrent) return;
    setState(() => _switching = true);
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
      if (mounted) setState(() => _switching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final isActive = site.operationalStatus == 'active';

    return Card(
      color: widget.isCurrent ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: _switching ? null : _select,
        leading: Icon(
          widget.isCurrent ? Icons.check_circle : Icons.apartment_outlined,
          color: widget.isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey,
        ),
        title: Text(site.name),
        subtitle: Text('${site.code} · ${isActive ? 'Operational' : site.operationalStatus}'),
        trailing: _switching
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : widget.isCurrent
                ? const Text('Current', style: TextStyle(fontWeight: FontWeight.w600))
                : const Icon(Icons.chevron_right),
      ),
    );
  }
}
