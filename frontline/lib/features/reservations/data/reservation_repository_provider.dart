import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import 'http_reservation_repository.dart';
import 'mock_reservation_repository.dart';
import 'reservation_repository.dart';

part 'reservation_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ReservationRepository reservationRepository(Ref ref) {
  if (AppConfig.useMock) return MockReservationRepository();
  final db = ref.watch(appDatabaseProvider);
  return HttpReservationRepository(ref.watch(dioClientProvider), db);
}
