import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'asset_repository.dart';
import 'http_asset_repository.dart';
import 'mock_asset_repository.dart';

part 'asset_repository_provider.g.dart';

@Riverpod(keepAlive: true)
AssetRepository assetRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockAssetRepository(db);
  return HttpAssetRepository(ref.watch(dioClientProvider), db);
}
