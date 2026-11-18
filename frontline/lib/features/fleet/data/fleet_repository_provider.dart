import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'fleet_repository.dart';
import 'http_fleet_repository.dart';
import 'mock_fleet_repository.dart';

part 'fleet_repository_provider.g.dart';

@Riverpod(keepAlive: true)
FleetRepository fleetRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockFleetRepository(db);
  return HttpFleetRepository(ref.watch(dioClientProvider), db);
}
