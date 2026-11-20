import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_permit_repository.dart';
import 'mock_permit_repository.dart';
import 'permit_repository.dart';

part 'permit_repository_provider.g.dart';

@Riverpod(keepAlive: true)
PermitRepository permitRepository(Ref ref) {
  if (AppConfig.useMock) return MockPermitRepository();
  final db = ref.watch(appDatabaseProvider);
  return HttpPermitRepository(ref.watch(dioClientProvider), db);
}
