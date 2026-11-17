import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Asset register (Section 32) and asset meters (Section 33), cached
/// locally so a technician can scan a QR code and see full asset context
/// (health, criticality, warranty, history) with zero network round trip.
class Assets extends Table {
  TextColumn get id => text()();
  TextColumn get assetCode => text()();
  TextColumn get qrCode => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get name => text()();
  TextColumn get categoryId => text()();
  TextColumn get manufacturer => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  TextColumn get criticality => text()(); // low|medium|high|critical
  TextColumn get status => text()(); // operational|down|maintenance|retired
  RealColumn get healthScore => real().nullable()();
  DateTimeColumn get warrantyEndDate => dateTime().nullable()();
  DateTimeColumn get lastServiceDate => dateTime().nullable()();
  IntColumn get repeatFailureCount => integer().withDefault(const Constant(0))();

  // Commercial + maintenance-planning fields (Screen 12 "Commercial" and
  // "Maintenance" sections). Vendor is kept as a plain name rather than
  // a foreign key into a vendor table - full vendor management (Section
  // 38-40) is a manager/desktop concern, not part of this mobile app.
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get purchaseCost => real().nullable()();
  TextColumn get vendorName => text().nullable()();
  DateTimeColumn get amcEndDate => dateTime().nullable()();
  DateTimeColumn get nextServiceDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Read-only cache of asset-linked documents (Screen 12: manual,
/// warranty, drawing, SOP, certificates - Section 50). The mobile app
/// never creates these, only displays what's synced down.
class AssetDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text().references(Assets, #id)();
  TextColumn get documentType => text()(); // manual|warranty|drawing|sop|certificate
  TextColumn get title => text()();
  TextColumn get url => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class AssetMeters extends Table {
  TextColumn get id => text()();
  TextColumn get assetId => text().references(Assets, #id)();
  TextColumn get meterType => text()(); // runtime_hours|cycles|temperature...
  TextColumn get unit => text()();
  RealColumn get currentValue => real().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Meter readings captured by a technician in the field. Always written
/// locally first and pushed through the outbox - this is one of the
/// canonical offline-mutation flows (Section 33: sources include Manual).
class MeterReadings extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get meterId => text().references(AssetMeters, #id)();
  TextColumn get workOrderId => text().nullable()();
  RealColumn get value => real()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get capturedBy => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
