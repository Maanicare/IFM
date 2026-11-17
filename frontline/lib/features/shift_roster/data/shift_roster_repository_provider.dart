import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_shift_roster_repository.dart';
import 'mock_shift_roster_repository.dart';
import 'shift_roster_repository.dart';

part 'shift_roster_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ShiftRosterRepository shiftRosterRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  if (AppConfig.useMock) return MockShiftRosterRepository(db);
  return HttpShiftRosterRepository(ref.watch(dioClientProvider), db);
}
