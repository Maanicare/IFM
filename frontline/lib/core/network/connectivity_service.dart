import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Thin wrapper over `connectivity_plus` so the rest of the app depends on
/// a single, mockable abstraction rather than the plugin directly.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  Stream<bool> onStatusChange() => _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService(Connectivity());
}

/// Live stream of online/offline state, consumed by the sync engine and by
/// UI banners ("You're offline - changes will sync automatically").
@Riverpod(keepAlive: true)
Stream<bool> isOnline(Ref ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onStatusChange().asBroadcastStream();
}
