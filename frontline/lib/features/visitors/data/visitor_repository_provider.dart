import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_visitor_repository.dart';
import 'mock_visitor_repository.dart';
import 'visitor_repository.dart';

part 'visitor_repository_provider.g.dart';

@Riverpod(keepAlive: true)
VisitorRepository visitorRepository(Ref ref) {
  if (AppConfig.useMock) return MockVisitorRepository();
  final db = ref.watch(appDatabaseProvider);
  return HttpVisitorRepository(ref.watch(dioClientProvider), db);
}
