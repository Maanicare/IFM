import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'trip_controller.g.dart';

/// Backs Screen 48's driver-facing subset: start a trip (capturing the
/// start odometer), end it later (end odometer, optional fuel used).
/// Same offline-first write-then-outbox pattern as every other mutation
/// in this app.
@riverpod
class TripController extends _$TripController {
  @override
  void build() {}

  Future<void> startTrip({
    required String vehicleId,
    required double startOdometer,
    String? purpose,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageFleetTrip);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.fleetDao.insertTrip(TripsCompanion.insert(
        id: id,
        vehicleId: vehicleId,
        driverId: accessContext.userId,
        startTime: now,
        startOdometer: startOdometer,
        purpose: Value(purpose),
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'fleet_trip',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'tripId': id}),
        createdBy: accessContext.userId,
      );
    });
  }

  Future<void> endTrip({
    required String tripId,
    required double endOdometer,
    double? fuelUsed,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.manageFleetTrip);

    final now = DateTime.now();

    await db.transaction(() async {
      await db.fleetDao.updateTripEnd(
        tripId: tripId,
        endTime: now,
        endOdometer: endOdometer,
        fuelUsed: fuelUsed,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'fleet_trip',
        entityId: tripId,
        operation: 'update',
        payloadJson: jsonEncode({'tripId': tripId}),
        createdBy: accessContext.userId,
      );
    });
  }
}
