import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'fleet_repository.dart';

class MockFleetRepository implements FleetRepository {
  MockFleetRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncAssignedVehicle(String driverId) async {
    final list = await FixtureLoader.loadJson('assets/fixtures/vehicles.json') as List;

    await _db.transaction(() async {
      for (final v in list.cast<Map<String, dynamic>>()) {
        if (v['assignedDriverId'] != driverId) continue;
        await _db.fleetDao.upsertVehicleFromServer(VehiclesCompanion.insert(
          id: v['id'] as String,
          registration: v['registration'] as String,
          type: v['type'] as String,
          make: Value(v['make'] as String?),
          model: Value(v['model'] as String?),
          odometer: Value((v['odometer'] as num?)?.toDouble()),
          fuelType: Value(v['fuelType'] as String?),
          assignedDriverId: Value(v['assignedDriverId'] as String?),
          status: v['status'] as String,
          insuranceExpiry: Value(
            v['insuranceExpiry'] != null ? DateTime.parse(v['insuranceExpiry'] as String) : null,
          ),
          pucExpiry: Value(
            v['pucExpiry'] != null ? DateTime.parse(v['pucExpiry'] as String) : null,
          ),
          serviceDueDate: Value(
            v['serviceDueDate'] != null ? DateTime.parse(v['serviceDueDate'] as String) : null,
          ),
        ));
      }
    });
  }

  @override
  Future<void> pushTrip(String tripId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
