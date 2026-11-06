import 'dart:async';

import 'package:bramwells_precision_test_kit/app/navigation/deferred_workspace_page.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a failed page download can be retried', (tester) async {
    final first = Completer<void>();
    final second = Completer<void>();
    final downloads = [first.future, second.future].iterator;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeferredWorkspacePage(
          load: () {
            downloads.moveNext();
            return downloads.current;
          },
          builder: (_) => const Text('Loaded workspace page'),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loaded workspace page'), findsNothing);

    first.completeError(StateError('Download failed'));
    await tester.pump();
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    second.complete();
    await tester.pumpAndSettle();
    expect(find.text('Loaded workspace page'), findsOneWidget);
  });
}
