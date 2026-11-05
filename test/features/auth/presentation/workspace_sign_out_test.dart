import 'dart:async';

import 'package:bramwells_precision_test_kit/features/auth/presentation/workspace_sign_out.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_configuration.dart';

void main() {
  testWidgets('saves before sign-out and blocks duplicate requests and Back', (
    tester,
  ) async {
    final save = Completer<void>();
    final calls = <String>[];
    final operation = WorkspaceSignOut(
      flush: () {
        calls.add('save');
        return save.future;
      },
      signOut: () async {
        calls.add('signOut');
      },
    );
    late BuildContext pageContext;
    await pumpConfiguredWidget(
      tester,
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            pageContext = context;
            return Scaffold(
              body: TextButton(
                onPressed: () => unawaited(operation.run(context)),
                child: const Text('Sign out'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(calls, ['save']);
    expect(find.text('Saving and signing out…'), findsOneWidget);
    await operation.run(pageContext);
    expect(calls, ['save']);
    await Navigator.of(pageContext).maybePop();
    await tester.pump();
    expect(find.text('Saving and signing out…'), findsOneWidget);
    save.complete();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(calls, ['save', 'signOut']);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('save failure leaves the session active and permits retry', (
    tester,
  ) async {
    var failSave = true;
    var signOuts = 0;
    final operation = WorkspaceSignOut(
      flush: () async {
        if (failSave) {
          throw StateError('disk full');
        }
      },
      signOut: () async {
        signOuts++;
      },
    );
    await pumpConfiguredWidget(
      tester,
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => unawaited(operation.run(context)),
              child: const Text('Sign out'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(signOuts, 0);
    expect(
      find.textContaining('Your changes could not be saved'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    failSave = false;
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(signOuts, 1);
  });

  testWidgets('auth transition can dispose the navigator during sign-out', (
    tester,
  ) async {
    final signedIn = ValueNotifier(true);
    addTearDown(signedIn.dispose);
    final operation = WorkspaceSignOut(
      flush: () async {},
      signOut: () async {
        signedIn.value = false;
        // Exercise cleanup after the old app/navigation tree was removed.
        await WidgetsBinding.instance.endOfFrame;
      },
    );
    await pumpConfiguredWidget(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: signedIn,
        builder: (_, active, _) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          key: ValueKey(active),
          home: active
              ? Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => unawaited(operation.run(context)),
                      child: const Text('Sign out'),
                    ),
                  ),
                )
              : const Scaffold(body: Text('Sign in')),
        ),
      ),
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
