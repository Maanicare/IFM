import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

/// Wires up every layer of Dart/Flutter error reporting into [AppLogger] so
/// that nothing - a widget build error, an async Future rejection, or a
/// platform-channel exception - is ever lost silently on a field device
/// where no debugger is attached.
///
/// Call [GlobalErrorHandler.run] as the very first thing in `main()`,
/// wrapping the call to `runApp`.
class GlobalErrorHandler {
  const GlobalErrorHandler._();

  static const _tag = 'GlobalError';

  static void run(void Function() appRunner) {
    // Catches synchronous errors thrown by the Flutter framework itself
    // (e.g. a failed widget build) that would otherwise only show as a red
    // screen with no persisted record.
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLogger.instance.fatal(
        _tag,
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
        context: {'library': details.library},
      );
      FlutterError.presentError(details);
    };

    // Catches errors escaping the engine/platform boundary (e.g. unhandled
    // errors in platform channel callbacks) that FlutterError.onError does
    // not see.
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      AppLogger.instance.fatal(
        _tag,
        'PlatformDispatcher error: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return true; // handled - do not crash the process.
    };

    // runZonedGuarded is the outermost net: it catches anything thrown
    // asynchronously (unawaited futures, timers, stream callbacks) anywhere
    // in the zone, including before runApp is called.
    runZonedGuarded(appRunner, (error, stackTrace) {
      AppLogger.instance.fatal(
        _tag,
        'Uncaught zone error: $error',
        error: error,
        stackTrace: stackTrace,
      );
    });
  }
}
