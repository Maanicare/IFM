import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/checklist_tables.dart';

part 'checklist_dao.g.dart';

@DriftAccessor(tables: [Checklists, ChecklistItems, ChecklistResponses])
class ChecklistDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistDaoMixin {
  ChecklistDao(super.db);

  Future<List<ChecklistItem>> itemsFor(String checklistId) {
    return (select(checklistItems)
          ..where((t) => t.checklistId.equals(checklistId))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
  }

  Stream<List<ChecklistResponse>> watchResponsesFor(String workOrderId) {
    return (select(checklistResponses)
          ..where((t) => t.workOrderId.equals(workOrderId)))
        .watch();
  }

  /// Records (or replaces) a technician's answer to one checklist item.
  /// Upsert semantics so re-answering a question before submission doesn't
  /// create duplicate response rows.
  Future<void> recordResponse(ChecklistResponsesCompanion response) {
    return into(checklistResponses).insertOnConflictUpdate(response);
  }

  Future<void> upsertChecklist(ChecklistsCompanion checklist) =>
      into(checklists).insertOnConflictUpdate(checklist);

  Future<void> upsertItem(ChecklistItemsCompanion item) =>
      into(checklistItems).insertOnConflictUpdate(item);

  /// True when every `required` item on the checklist has a recorded
  /// response - gates whether the technician may submit work completion.
  Future<bool> isComplete({
    required String checklistId,
    required String workOrderId,
  }) async {
    final items = await itemsFor(checklistId);
    final requiredIds =
        items.where((i) => i.required).map((i) => i.id).toSet();
    if (requiredIds.isEmpty) return true;

    final responses = await (select(checklistResponses)
          ..where((t) => t.workOrderId.equals(workOrderId)))
        .get();
    final answeredIds = responses.map((r) => r.itemId).toSet();
    return requiredIds.difference(answeredIds).isEmpty;
  }
}
