import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_inspection_repository.dart';
import 'inspection_repository.dart';
import 'mock_inspection_repository.dart';

part 'inspection_repository_provider.g.dart';

@Riverpod(keepAlive: true)
InspectionRepository inspectionRepository(Ref ref) {
  if (AppConfig.useMock) return MockInspectionRepository();
  final db = ref.watch(appDatabaseProvider);
  return HttpInspectionRepository(ref.watch(dioClientProvider), db);
}
