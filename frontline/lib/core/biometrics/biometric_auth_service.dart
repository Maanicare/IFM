import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` for Screen 01's "Biometric login
/// after first authentication". Device-capability checks and the actual
/// prompt live here; what happens after a successful prompt (re-running
/// login with a remembered identifier) is the caller's job.
class BiometricAuthService {
  const BiometricAuthService._();

  static final _auth = LocalAuthentication();

  /// Whether [authenticate] even has a chance of succeeding on this
  /// device. Deliberately checks `isDeviceSupported` alone, not ANDed
  /// with `canCheckBiometrics` - a device with no fingerprint/face
  /// enrolled but a PIN/pattern set still supports authentication via
  /// [authenticate]'s device-credential fallback (`biometricOnly:
  /// false` below), so requiring enrolled biometrics here would block a
  /// login path that actually works.
  static Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
