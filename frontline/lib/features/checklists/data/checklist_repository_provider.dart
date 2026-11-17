import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'checklist_repository.dart';
import 'http_checklist_repository.dart';
import 'mock_checklist_repository.dart';

part 'checklist_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ChecklistRepository checklistRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockChecklistRepository(db);
  return HttpChecklistRepository(ref.watch(dioClientProvider), db);
}
