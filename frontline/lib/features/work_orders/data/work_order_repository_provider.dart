import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_work_order_repository.dart';
import 'mock_work_order_repository.dart';
import 'work_order_repository.dart';

part 'work_order_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WorkOrderRepository workOrderRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockWorkOrderRepository(db);
  return HttpWorkOrderRepository(ref.watch(dioClientProvider), db);
}
