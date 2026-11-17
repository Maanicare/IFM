import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_inventory_repository.dart';
import 'inventory_repository.dart';
import 'mock_inventory_repository.dart';

part 'inventory_repository_provider.g.dart';

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockInventoryRepository(db);
  return HttpInventoryRepository(ref.watch(dioClientProvider), db);
}
