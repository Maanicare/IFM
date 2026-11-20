import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Comfort Feedback (Screen 46). "Automatically map feedback to
/// location" means the current site/space context, captured the same
/// way Create Request auto-collects it - not a new location-detection
/// mechanism. "...and sensor context" isn't modelled - this app has no
/// IoT/sensor integration anywhere (same conclusion reached for
/// Washroom's sensor alerts and Reservation's Temperature/IAQ).
class ComfortFeedbackEntries extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get category =>
      text()(); // too_hot|too_cold|noise|air_quality|lighting|cleanliness|other
  TextColumn get note => text().nullable()();
  TextColumn get submittedBy => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
