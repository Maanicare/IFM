import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_identity_repository.dart';
import 'identity_repository.dart';
import 'mock_identity_repository.dart';

part 'identity_repository_provider.g.dart';

@Riverpod(keepAlive: true)
IdentityRepository identityRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockIdentityRepository(db);
  return HttpIdentityRepository(
    ref.watch(dioClientProvider),
    db,
    ref.watch(tokenStorageProvider),
  );
}
