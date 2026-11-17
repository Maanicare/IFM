import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/safety_gate_tables.dart';

part 'safety_gate_dao.g.dart';

@DriftAccessor(tables: [SafetyGateResponses])
class SafetyGateDao extends DatabaseAccessor<AppDatabase>
    with _$SafetyGateDaoMixin {
  SafetyGateDao(super.db);

  Future<void> insertLocal(SafetyGateResponsesCompanion row) =>
      into(safetyGateResponses).insert(row);

  /// Whether the safety gate has already been answered for this work
  /// order - asked once per job, not on every resume (Section 11: the
  /// gate is about starting the work, not re-litigating it after every
  /// blocker/resume cycle).
  Future<bool> hasAnsweredFor(String workOrderId) async {
    final existing = await (select(safetyGateResponses)
          ..where((t) => t.workOrderId.equals(workOrderId))
          ..limit(1))
        .getSingleOrNull();
    return existing != null;
  }

  Future<List<SafetyGateResponse>> responsesFor(String workOrderId) =>
      (select(safetyGateResponses)..where((t) => t.workOrderId.equals(workOrderId))).get();
}
