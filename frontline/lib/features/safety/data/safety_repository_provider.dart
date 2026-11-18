import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_safety_repository.dart';
import 'mock_safety_repository.dart';
import 'safety_repository.dart';

part 'safety_repository_provider.g.dart';

@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) {
  if (AppConfig.useMock) return MockSafetyRepository();
  return HttpSafetyRepository(ref.watch(dioClientProvider), ref.watch(appDatabaseProvider));
}
