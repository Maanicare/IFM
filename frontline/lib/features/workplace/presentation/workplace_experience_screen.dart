import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// SCREEN 42 - Workplace Experience (Employee Side hub). A navigation
/// hub into other screens, not an owner of its own data - "Request
/// service" and "Report issue" both go to the existing Create Request
/// flow (Screen 06), since this app's data model doesn't distinguish
/// a "service request" from an "issue report". "Book desk" and "Book
/// room" both go to the same Screen 43 (Reservation) list - this
/// app's `Spaces` model doesn't distinguish a bookable desk from a
/// bookable room as different entities, just reservable Spaces.
/// "Visitor" goes to Screen 44 (Visitor Management). "Events" and
/// "Amenities" have no owning screen or data
/// model anywhere in this app; "Wayfinding" needs floor-plan/indoor-map
/// data that's a Web/Site Digital Map (Screen 18) concern. All four
/// are tracked in PENDING_FEATURES.md.
class WorkplaceExperienceScreen extends StatelessWidget {
  const WorkplaceExperienceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workplace')),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _Tile(
            icon: Icons.add_circle_outline,
            label: 'Report issue',
            onTap: () => context.push('/requests/new'),
          ),
          _Tile(
            icon: Icons.support_agent_outlined,
            label: 'Request service',
            onTap: () => context.push('/requests/new'),
          ),
          _Tile(
            icon: Icons.desk_outlined,
            label: 'Book desk',
            onTap: () => context.push('/reservations'),
          ),
          _Tile(
            icon: Icons.meeting_room_outlined,
            label: 'Book room',
            onTap: () => context.push('/reservations'),
          ),
          _Tile(
            icon: Icons.badge_outlined,
            label: 'Visitor',
            onTap: () => context.push('/visitors'),
          ),
          _Tile(
            icon: Icons.event_outlined,
            label: 'Events',
            onTap: () => _comingSoon(context, 'Events'),
          ),
          _Tile(
            icon: Icons.local_cafe_outlined,
            label: 'Amenities',
            onTap: () => _comingSoon(context, 'Amenities'),
          ),
          _Tile(
            icon: Icons.map_outlined,
            label: 'Wayfinding',
            onTap: () => _comingSoon(context, 'Wayfinding'),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is not available yet.')),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
