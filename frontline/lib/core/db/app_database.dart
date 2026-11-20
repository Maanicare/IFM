import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// ensures native sqlite3 is bundled

import 'daos/asset_dao.dart';
import 'daos/attachment_dao.dart';
import 'daos/checklist_dao.dart';
import 'daos/cleaning_task_dao.dart';
import 'daos/fleet_dao.dart';
import 'daos/identity_dao.dart';
import 'daos/inventory_dao.dart';
import 'daos/location_dao.dart';
import 'daos/notification_dao.dart';
import 'daos/outbox_dao.dart';
import 'daos/request_dao.dart';
import 'daos/safety_dao.dart';
import 'daos/safety_gate_dao.dart';
import 'daos/shift_handover_dao.dart';
import 'daos/shift_roster_dao.dart';
import 'daos/soft_service_inspection_dao.dart';
import 'daos/washroom_dao.dart';
import 'daos/work_order_dao.dart';
import 'tables/asset_tables.dart';
import 'tables/attachment_tables.dart';
import 'tables/checklist_tables.dart';
import 'tables/cleaning_task_tables.dart';
import 'tables/fleet_tables.dart';
import 'tables/identity_tables.dart';
import 'tables/inventory_tables.dart';
import 'tables/location_tables.dart';
import 'tables/notification_table.dart';
import 'tables/outbox_table.dart';
import 'tables/request_tables.dart';
import 'tables/safety_gate_tables.dart';
import 'tables/safety_tables.dart';
import 'tables/shift_handover_tables.dart';
import 'tables/shift_roster_tables.dart';
import 'tables/soft_service_inspection_tables.dart';
import 'tables/washroom_tables.dart';
import 'tables/work_order_tables.dart';

part 'app_database.g.dart';

/// The single offline-first relational store for the frontline app.
///
/// Holds the full relational graph described in the architecture brief:
/// WorkOrders -> Checklists -> ChecklistItems -> ChecklistResponses,
/// Asset -> AssetMeters -> MeterReadings, plus the location hierarchy,
/// service requests, the attachment queue and the outbox sync queue.
///
/// All reference data (sites/assets/checklists/work orders as assigned)
/// flows one-way from server -> device via `upsertFromServer` calls; all
/// user-authored mutations flow device -> server through [OutboxEntries].
@DriftDatabase(
  tables: [
    Sites,
    Buildings,
    Floors,
    Spaces,
    Assets,
    AssetMeters,
    MeterReadings,
    AssetDocuments,
    ServiceRequests,
    WorkOrders,
    WorkOrderStatusHistory,
    WorkOrderPlannedParts,
    Checklists,
    ChecklistItems,
    ChecklistResponses,
    Attachments,
    OutboxEntries,
    CachedUsers,
    AppNotifications,
    InventoryItems,
    InventoryBalances,
    InventoryTransactions,
    ShiftHandovers,
    ShiftRosterEntries,
    SafetyGateResponses,
    Incidents,
    Hazards,
    Vehicles,
    Trips,
    CleaningTasks,
    CleaningTaskInspectionPoints,
    CleaningTaskInspectionResponses,
    RequestComments,
    Washrooms,
    SoftServiceInspections,
  ],
  daos: [
    LocationDao,
    AssetDao,
    RequestDao,
    WorkOrderDao,
    ChecklistDao,
    AttachmentDao,
    OutboxDao,
    IdentityDao,
    NotificationDao,
    InventoryDao,
    ShiftHandoverDao,
    ShiftRosterDao,
    SafetyGateDao,
    SafetyDao,
    FleetDao,
    CleaningTaskDao,
    WashroomDao,
    SoftServiceInspectionDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Named constructor used by tests to run entirely in memory.
  AppDatabase.forTesting(super.executor);

  // IMPORTANT: bump this on every table/column change from now on. It
  // was left at 1 through several rounds of added columns/tables
  // earlier in this app's history, so an install from that period opens
  // its on-disk sqlite file expecting the *old* table shape - querying
  // a column that was added since (e.g. CachedUsers.recentSiteIdsJson)
  // then fails with a Drift row-mapping error ("Null check operator
  // used on a null value"), not a clean "no such column" message.
  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Pre-release app, still under active schema changes - there
          // is no production data to preserve yet, so a destructive
          // recreate is simpler and safer than reconstructing the exact
          // sequence of columns added across versions that were never
          // individually bumped. Once this app has real installs with
          // data worth keeping, replace this with proper per-version
          // `m.addColumn`/`m.createTable` steps.
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'onemaanicare_frontline.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
