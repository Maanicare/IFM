// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_dao.dart';

// ignore_for_file: type=lint
mixin _$AssetDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $AssetsTable get assets => attachedDatabase.assets;
  $AssetMetersTable get assetMeters => attachedDatabase.assetMeters;
  $MeterReadingsTable get meterReadings => attachedDatabase.meterReadings;
  $AssetDocumentsTable get assetDocuments => attachedDatabase.assetDocuments;
  AssetDaoManager get managers => AssetDaoManager(this);
}

class AssetDaoManager {
  final _$AssetDaoMixin _db;
  AssetDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db.attachedDatabase, _db.assets);
  $$AssetMetersTableTableManager get assetMeters =>
      $$AssetMetersTableTableManager(_db.attachedDatabase, _db.assetMeters);
  $$MeterReadingsTableTableManager get meterReadings =>
      $$MeterReadingsTableTableManager(_db.attachedDatabase, _db.meterReadings);
  $$AssetDocumentsTableTableManager get assetDocuments =>
      $$AssetDocumentsTableTableManager(
        _db.attachedDatabase,
        _db.assetDocuments,
      );
}
