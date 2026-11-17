import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/biometrics/biometric_auth_service.dart';
import '../../../core/biometrics/biometric_preference.dart';
import '../../../core/config/app_config.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/app_strings.dart';
import 'auth_controller.dart';

/// SCREEN 01 - Login. Identifier + password, plus biometric (once
/// enabled from More, Screen 54-adjacent) and SSO. SSO has no real
/// identity provider behind it in this app - see [_handleSso] - and is
/// not faked as a working login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController(
    text: AppConfig.useMock ? 'arjun.mehta@onemaanicare.com' : '',
  );
  final _passwordController = TextEditingController(
    text: AppConfig.useMock ? 'demo' : '',
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading && authState.hasValue == false;
    final language = ref.watch(appLocaleProvider).value ?? 'en';
    String t(String key) => AppStrings.of(key, language);
    final biometricPref = ref.watch(biometricPreferenceProvider).value;
    final biometricReady = biometricPref?.enabled == true && biometricPref?.identifier != null;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error.toString())),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: _LanguageSelector(
                      value: language,
                      onChanged: (v) => ref.read(appLocaleProvider.notifier).setLanguage(v),
                    ),
                  ),
                  const Icon(Icons.apartment, size: 56, color: Color(0xFF0B5FFF)),
                  const SizedBox(height: 12),
                  Text(
                    t('appTitle'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    t('appSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _identifierController,
                    decoration: InputDecoration(labelText: t('identifierLabel')),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(labelText: t('passwordLabel')),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t('loginButton')),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () {}, child: Text(t('forgotPassword'))),
                  if (biometricReady) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.fingerprint),
                      onPressed: isLoading ? null : () => _handleBiometricLogin(biometricPref!.identifier!),
                      label: Text(t('biometricLogin')),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.badge_outlined),
                    onPressed: isLoading ? null : _handleSso,
                    label: Text(t('ssoLogin')),
                  ),
                  if (AppConfig.useMock)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        t('mockModeHint'),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );
  }

  /// Screen 01: "Biometric login after first authentication". The
  /// device prompt gates re-running login with the identifier
  /// remembered when biometric login was enabled (More screen) - no
  /// password is stored, so this only actually completes in mock mode
  /// (any password is accepted there); a real backend would need this
  /// to exchange a stored device/refresh token instead of a password.
  Future<void> _handleBiometricLogin(String identifier) async {
    final supported = await BiometricAuthService.isDeviceSupported();
    if (!supported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication is not available on this device.')),
      );
      return;
    }
    final confirmed = await BiometricAuthService.authenticate(
      reason: 'Log in to IFM',
    );
    if (!confirmed) return;
    ref.read(authControllerProvider.notifier).login(identifier, '');
  }

  /// Screen 01: "SSO option". This app has no identity provider wired
  /// up - rather than fake a working login, it's explicit about what's
  /// missing in non-mock mode. Mock mode logs in as the seeded demo
  /// user so the button is still exercisable end to end.
  void _handleSso() {
    if (AppConfig.useMock) {
      ref.read(authControllerProvider.notifier).login('arjun.mehta@onemaanicare.com', 'sso');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SSO requires an enterprise identity provider to be configured for this organisation.')),
    );
  }
}

/// Screen 01: "language selector". English/Hindi per Section 61's
/// recommended initial languages.
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      icon: const Icon(Icons.language, size: 18),
      items: supportedLanguages.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
