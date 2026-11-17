import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_request_repository.dart';
import 'mock_request_repository.dart';
import 'request_repository.dart';

part 'request_repository_provider.g.dart';

@Riverpod(keepAlive: true)
RequestRepository requestRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockRequestRepository(db);
  return HttpRequestRepository(ref.watch(dioClientProvider), db);
}
