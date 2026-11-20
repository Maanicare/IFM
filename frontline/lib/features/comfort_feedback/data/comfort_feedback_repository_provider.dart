import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'comfort_feedback_repository.dart';
import 'http_comfort_feedback_repository.dart';
import 'mock_comfort_feedback_repository.dart';

part 'comfort_feedback_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ComfortFeedbackRepository comfortFeedbackRepository(Ref ref) {
  if (AppConfig.useMock) return MockComfortFeedbackRepository();
  final db = ref.watch(appDatabaseProvider);
  return HttpComfortFeedbackRepository(ref.watch(dioClientProvider), db);
}
