import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/error/global_error_handler.dart';

/// Entry point. [GlobalErrorHandler.run] wraps everything - including the
/// call to [WidgetsFlutterBinding.ensureInitialized] - so no error at any
/// layer (sync, async, framework, or platform) can escape unlogged
/// (Section: Enterprise Error Handling & NDJSON Local Logger).
void main() {
  GlobalErrorHandler.run(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(const ProviderScope(child: OneMaanicareFrontlineApp()));
  });
}
