import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontline/app.dart';
import 'package:frontline/core/db/app_database.dart';

void main() {
  testWidgets('App boots to the login screen when logged out', (tester) async {
    // The real [appDatabaseProvider] opens a native sqlite file via
    // path_provider, which has no platform implementation in a plain
    // widget test and throws before the app ever renders. An in-memory
    // test database (the same `AppDatabase.forTesting` constructor used
    // for DAO-level tests) avoids that without touching app code.
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(testDb.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(testDb)],
        child: const OneMaanicareFrontlineApp(),
      ),
    );
    // Login resolves asynchronously (DB open + auth-state check) before
    // routing to the login screen, so settle rather than pumping once.
    await tester.pumpAndSettle();

    expect(find.text('IFM'), findsWidgets);

    // Disposing the ProviderScope schedules a zero-duration Timer inside
    // drift's stream-query teardown (StreamQueryStore.markAsClosed). Done
    // here - while still inside a pump cycle - that timer gets a chance
    // to fire before the test ends, instead of the framework's final
    // "no pending timers" check tripping on a totally harmless one.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
