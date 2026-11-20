import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'cleaning_task_repository.dart';
import 'http_cleaning_task_repository.dart';
import 'mock_cleaning_task_repository.dart';

part 'cleaning_task_repository_provider.g.dart';

@Riverpod(keepAlive: true)
CleaningTaskRepository cleaningTaskRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockCleaningTaskRepository(db);
  return HttpCleaningTaskRepository(ref.watch(dioClientProvider), db);
}
