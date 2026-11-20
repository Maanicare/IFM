import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'reservation_controller.g.dart';

/// Backs Screen 43 (Reservation): Reserve/Invite/Order services/Check
/// in. Reserve/Invite/Order services are all captured in one step at
/// booking time (see the doc comment on [Reservations] for why Invite
/// and Order services are free text, not real sub-systems).
@riverpod
class ReservationController extends _$ReservationController {
  @override
  void build() {}

  Future<String> reserve({
    required String spaceId,
    required String siteId,
    required DateTime startTime,
    required DateTime endTime,
    int? attendeeCount,
    String? purpose,
    String? inviteesNote,
    String? servicesNote,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot reserve a space without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.createServiceRequest, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.reservationDao.insert(ReservationsCompanion.insert(
        id: id,
        spaceId: spaceId,
        organiserId: accessContext.userId,
        organiserName: accessContext.userId,
        startTime: startTime,
        endTime: endTime,
        attendeeCount: Value(attendeeCount),
        purpose: Value(purpose),
        inviteesNote: Value(inviteesNote),
        servicesNote: Value(servicesNote),
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'reservation',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'reservationId': id}),
        createdBy: accessContext.userId,
      );
    });
    return id;
  }

  Future<void> cancel(String reservationId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.createServiceRequest, siteId: siteId);

    await db.transaction(() async {
      await db.reservationDao.cancel(reservationId);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'reservation_cancel',
        entityId: reservationId,
        operation: 'update',
        payloadJson: jsonEncode({'reservationId': reservationId}),
        createdBy: accessContext.userId,
      );
    });
  }

  Future<void> checkIn(String reservationId, {required String siteId}) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.createServiceRequest, siteId: siteId);

    await db.transaction(() async {
      await db.reservationDao.checkIn(reservationId);
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'reservation_check_in',
        entityId: reservationId,
        operation: 'update',
        payloadJson: jsonEncode({'reservationId': reservationId}),
        createdBy: accessContext.userId,
      );
    });
  }
}
