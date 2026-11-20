import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'fleet_repository.dart';

class HttpFleetRepository implements FleetRepository {
  HttpFleetRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncAssignedVehicle(String driverId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/drivers/$driverId/vehicle');
    final v = response.data;
    if (v == null) return;

    await _db.fleetDao.upsertVehicleFromServer(VehiclesCompanion.insert(
      id: v['id'] as String,
      registration: v['registration'] as String,
      type: v['type'] as String,
      make: Value(v['make'] as String?),
      model: Value(v['model'] as String?),
      vin: Value(v['vin'] as String?),
      odometer: Value((v['odometer'] as num?)?.toDouble()),
      fuelType: Value(v['fuelType'] as String?),
      batteryStatus: Value(v['batteryStatus'] as String?),
      tyreStatus: Value(v['tyreStatus'] as String?),
      assignedDriverId: Value(driverId),
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

  @override
  Future<void> pushTrip(String tripId) async {
    final trip = await (_db.select(_db.trips)..where((t) => t.id.equals(tripId))).getSingleOrNull();
    if (trip == null) return;
    await _dio.post<void>('/v1/trips', data: {
      'id': trip.id,
      'vehicle_id': trip.vehicleId,
      'driver_id': trip.driverId,
      'start_time': trip.startTime.toIso8601String(),
      'end_time': trip.endTime?.toIso8601String(),
      'start_odometer': trip.startOdometer,
      'end_odometer': trip.endOdometer,
      'fuel_used': trip.fuelUsed,
      'purpose': trip.purpose,
    });
  }
}
