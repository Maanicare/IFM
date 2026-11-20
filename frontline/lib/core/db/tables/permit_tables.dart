import 'package:drift/drift.dart';

import 'location_tables.dart';
import 'work_order_tables.dart';

/// Permits (Section 43, Screen 37). `vendorId` in the canonical model
/// becomes a plain `vendorName` here - this app has no synced Vendor
/// directory (vendor management is a Web/Procurement concern). Risk
/// assessment is a free-text note plus an optional photo (via the
/// generic [Attachments] table, entityType `'permit'`), not a document
/// management system. "Authorised persons" is free text, same
/// reasoning as Incident's People involved/Witnesses - no employee
/// directory to pick specific people from.
class Permits extends Table {
  TextColumn get id => text()();
  TextColumn get permitNumber => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get workOrderId => text().nullable().references(WorkOrders, #id)();
  TextColumn get permitType =>
      text()(); // hot_work|height|confined_space|electrical|excavation|lifting|other
  TextColumn get vendorName => text().nullable()();
  DateTimeColumn get validFrom => dateTime()();
  DateTimeColumn get validTo => dateTime()();
  TextColumn get riskAssessmentNote => text().nullable()();
  TextColumn get authorisedPersons => text().nullable()();
  TextColumn get controlsNote => text().nullable()();
  TextColumn get isolationNote => text().nullable()();
  TextColumn get issuerName => text()();
  TextColumn get receiverName => text()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active|closed|cancelled
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
