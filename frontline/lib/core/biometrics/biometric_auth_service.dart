import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` for Screen 01's "Biometric login
/// after first authentication". Device-capability checks and the actual
/// prompt live here; what happens after a successful prompt (re-running
/// login with a remembered identifier) is the caller's job.
class BiometricAuthService {
  const BiometricAuthService._();

  static final _auth = LocalAuthentication();

  static Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
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
