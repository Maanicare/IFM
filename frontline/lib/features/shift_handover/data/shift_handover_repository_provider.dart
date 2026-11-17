import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_shift_handover_repository.dart';
import 'mock_shift_handover_repository.dart';
import 'shift_handover_repository.dart';

part 'shift_handover_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ShiftHandoverRepository shiftHandoverRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockShiftHandoverRepository(db);
  return HttpShiftHandoverRepository(ref.watch(dioClientProvider), db);
}
