import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'checklist_repository.dart';

class MockChecklistRepository implements ChecklistRepository {
  MockChecklistRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncTemplates() async {
    final data =
        await FixtureLoader.loadJson('assets/fixtures/checklists.json')
            as Map<String, dynamic>;

    await _db.transaction(() async {
      for (final c in (data['checklists'] as List).cast<Map<String, dynamic>>()) {
        await _db.checklistDao.upsertChecklist(ChecklistsCompanion.insert(
          id: c['id'] as String,
          name: c['name'] as String,
          version: c['version'] as int,
          category: c['category'] as String,
          active: Value(c['active'] as bool? ?? true),
        ));
      }
      for (final i in (data['items'] as List).cast<Map<String, dynamic>>()) {
        await _db.checklistDao.upsertItem(ChecklistItemsCompanion.insert(
          id: i['id'] as String,
          checklistId: i['checklistId'] as String,
          sequence: i['sequence'] as int,
          question: i['question'] as String,
          inputType: i['inputType'] as String,
          required: Value(i['required'] as bool? ?? true),
          minValue: Value((i['minValue'] as num?)?.toDouble()),
          maxValue: Value((i['maxValue'] as num?)?.toDouble()),
          failureAction: Value(i['failureAction'] as String?),
        ));
      }
    });
  }

  @override
  Future<void> pushResponse({
    required String workOrderId,
    required String itemId,
    required String responseJson,
    required String capturedBy,
    required DateTime capturedAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
