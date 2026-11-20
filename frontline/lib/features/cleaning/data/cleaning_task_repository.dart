/// Syncs assigned cleaning tasks (Screen 21) for a site and pushes
/// completion back once a technician finishes the inspection checklist.
abstract interface class CleaningTaskRepository {
  Future<void> syncAssignedTasks({required String userId, required String siteId});

  Future<void> pushCompletion(String cleaningTaskId);
}
