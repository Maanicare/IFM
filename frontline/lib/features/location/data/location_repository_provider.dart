import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_location_repository.dart';
import 'location_repository.dart';
import 'mock_location_repository.dart';

part 'location_repository_provider.g.dart';

/// Chooses the mock or HTTP implementation at the single point every other
/// provider depends on, per `--dart-define=USE_MOCK`. This is the pattern
/// repeated identically for every other feature's repository provider.
@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) {
    return MockLocationRepository(db);
  }
  final dio = ref.watch(dioClientProvider);
  return HttpLocationRepository(dio, db);
}
