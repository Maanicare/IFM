/// Minimal localisation dictionary (Section 61: "Recommended initial
/// languages: English and Hindi"). A hand-rolled key->translation map
/// rather than full ARB/gen-l10n scaffolding - this covers the places
/// the spec explicitly calls out (Screen 01's language selector, the
/// five flat nav labels) rather than attempting to translate every
/// string in the app in one pass. Voice input (Section 61) is handled
/// separately by the device's own speech recognizer, which already
/// accepts the system's input language regardless of this setting.
class AppStrings {
  const AppStrings._();

  static const Map<String, Map<String, String>> _dict = {
    'appTitle': {'en': 'OneMaanicare', 'hi': 'वनमानिकेयर'},
    'appSubtitle': {'en': 'Frontline', 'hi': 'फ्रंटलाइन'},
    'languageLabel': {'en': 'Language', 'hi': 'भाषा'},
    'identifierLabel': {'en': 'Email, mobile or employee ID', 'hi': 'ईमेल, मोबाइल या कर्मचारी आईडी'},
    'passwordLabel': {'en': 'Password', 'hi': 'पासवर्ड'},
    'loginButton': {'en': 'Log in', 'hi': 'लॉग इन करें'},
    'forgotPassword': {'en': 'Forgot password?', 'hi': 'पासवर्ड भूल गए?'},
    'biometricLogin': {'en': 'Log in with biometrics', 'hi': 'बायोमेट्रिक से लॉग इन करें'},
    'ssoLogin': {'en': 'Continue with SSO', 'hi': 'SSO से जारी रखें'},
    'mockModeHint': {
      'en': 'Mock mode - any password works for a seeded user.',
      'hi': 'मॉक मोड - किसी भी पासवर्ड से सीडेड यूज़र के लिए काम करेगा।',
    },
    'navHome': {'en': 'Home', 'hi': 'होम'},
    'navMyWork': {'en': 'My Work', 'hi': 'मेरा काम'},
    'navScan': {'en': 'Scan', 'hi': 'स्कैन'},
    'navRequests': {'en': 'Requests', 'hi': 'रिक्वेस्ट'},
    'navMore': {'en': 'More', 'hi': 'और'},
    'jobsAssigned': {'en': 'jobs assigned', 'hi': 'जॉब असाइन की गई'},
    'nothingUrgent': {'en': 'Nothing urgent right now', 'hi': 'अभी कुछ भी अर्जेंट नहीं है'},
    'viewAction': {'en': 'View', 'hi': 'देखें'},
    'reportIssue': {'en': 'Report issue', 'hi': 'समस्या बताएं'},
    'scanAsset': {'en': 'Scan asset', 'hi': 'एसेट स्कैन करें'},
    'exitTitle': {'en': 'Exit OneMaanicare?', 'hi': 'OneMaanicare से बाहर जाएं?'},
    'exitBody': {'en': 'Are you sure you want to exit the app?', 'hi': 'क्या आप वाकई ऐप से बाहर जाना चाहते हैं?'},
    'exitCancel': {'en': 'Cancel', 'hi': 'रद्द करें'},
    'exitConfirm': {'en': 'Exit', 'hi': 'बाहर जाएं'},
    'offlineBanner': {
      'en': "You're offline - changes will sync automatically",
      'hi': 'आप ऑफलाइन हैं - बदलाव अपने आप सिंक हो जाएंगे',
    },
  };

  static String of(String key, String languageCode) {
    return _dict[key]?[languageCode] ?? _dict[key]?['en'] ?? key;
  }
}
