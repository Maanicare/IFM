import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/identity/presentation/auth_controller.dart';
import 'user_role.dart';

part 'current_access_context_provider.g.dart';

/// Derives the [UserAccessContext] that [PolicyGuard] evaluates against
/// from the currently authenticated user. Null while logged out.
@riverpod
UserAccessContext? currentAccessContext(Ref ref) {
  final user = ref.watch(authControllerProvider).value;
  return user?.toAccessContext();
}
