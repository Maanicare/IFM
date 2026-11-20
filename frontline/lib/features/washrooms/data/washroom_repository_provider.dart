import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_washroom_repository.dart';
import 'mock_washroom_repository.dart';
import 'washroom_repository.dart';

part 'washroom_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WashroomRepository washroomRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockWashroomRepository(db);
  return HttpWashroomRepository(ref.watch(dioClientProvider), db);
}
