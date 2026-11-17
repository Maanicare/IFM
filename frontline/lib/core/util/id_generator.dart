import 'package:uuid/uuid.dart';

/// Single source of client-generated IDs, used for every locally-created
/// entity (requests, checklist responses, meter readings, outbox entries)
/// before the server assigns/confirms its own identifier.
class IdGenerator {
  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
