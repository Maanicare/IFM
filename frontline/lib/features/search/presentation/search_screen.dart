import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../location/presentation/current_site_provider.dart';

/// SCREEN 03 action: "Search" (Section 63 - Universal Search). Searches
/// everything this mobile app actually holds locally for the current
/// site: work orders, requests, assets, inventory items, spaces.
/// Vendor/employee/vehicle/document directories aren't modelled as
/// browsable lists in this app, so they're not included.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.watch(currentSiteIdProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search work orders, requests, assets, parts, rooms...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
      ),
      body: _query.length < 2 || siteId == null
          ? const Center(child: Text('Type at least 2 characters to search.'))
          : _SearchResults(siteId: siteId, query: _query),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.siteId, required this.query});
  final String siteId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return FutureBuilder<_SearchResultSet>(
      future: _SearchResultSet.load(db, siteId, query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('No matches.'));
        }
        return ListView(
          children: [
            _ResultSection(
              title: 'Work orders',
              items: results.workOrders.map((w) => _ResultTile(
                    icon: Icons.build_outlined,
                    title: w.woNumber,
                    subtitle: w.problemDescription ?? '',
                    onTap: () => context.push('/work-orders/${w.id}'),
                  )),
            ),
            _ResultSection(
              title: 'Requests',
              items: results.requests.map((r) => _ResultTile(
                    icon: Icons.list_alt_outlined,
                    title: r.requestNumber,
                    subtitle: r.title,
                    onTap: () => context.push('/requests/${r.id}'),
                  )),
            ),
            _ResultSection(
              title: 'Assets',
              items: results.assets.map((a) => _ResultTile(
                    icon: Icons.precision_manufacturing_outlined,
                    title: a.name,
                    subtitle: a.assetCode,
                    onTap: () => context.push('/assets/${a.id}'),
                  )),
            ),
            _ResultSection(
              title: 'Inventory items',
              items: results.inventoryItems.map((i) => _ResultTile(
                    icon: Icons.inventory_2_outlined,
                    title: i.name,
                    subtitle: i.sku,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${i.name} (${i.sku}) - open a work order to record usage.')),
                    ),
                  )),
            ),
            _ResultSection(
              title: 'Rooms / spaces',
              items: results.spaces.map((s) => _ResultTile(
                    icon: Icons.room_outlined,
                    title: s.name,
                    subtitle: s.spaceCode,
                    onTap: () => Navigator.of(context).pop(),
                  )),
            ),
          ],
        );
      },
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.items});
  final String title;
  final Iterable<_ResultTile> items;

  @override
  Widget build(BuildContext context) {
    final list = items.toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey)),
        ),
        ...list,
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

class _SearchResultSet {
  const _SearchResultSet({
    required this.workOrders,
    required this.requests,
    required this.assets,
    required this.inventoryItems,
    required this.spaces,
  });

  final List<WorkOrder> workOrders;
  final List<ServiceRequest> requests;
  final List<Asset> assets;
  final List<InventoryItem> inventoryItems;
  final List<Space> spaces;

  bool get isEmpty =>
      workOrders.isEmpty && requests.isEmpty && assets.isEmpty && inventoryItems.isEmpty && spaces.isEmpty;

  static Future<_SearchResultSet> load(AppDatabase db, String siteId, String query) async {
    final results = await Future.wait([
      db.workOrderDao.searchAtSite(siteId, query),
      db.requestDao.searchAtSite(siteId, query),
      db.assetDao.searchAtSite(siteId, query),
      db.inventoryDao.searchAtSite(siteId, query),
      db.locationDao.searchSpacesAtSite(siteId, query),
    ]);
    return _SearchResultSet(
      workOrders: results[0] as List<WorkOrder>,
      requests: results[1] as List<ServiceRequest>,
      assets: results[2] as List<Asset>,
      inventoryItems: results[3] as List<InventoryItem>,
      spaces: results[4] as List<Space>,
    );
  }
}
