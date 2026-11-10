import 'dart:async';

import 'package:bramwells_precision_test_kit/app/application.dart';
import 'package:bramwells_precision_test_kit/app/config/app_config.dart';
import 'package:bramwells_precision_test_kit/app/firebase/firebase_bootstrap.dart';
import 'package:bramwells_precision_test_kit/features/contact/api/contact_sender.dart';
import 'package:bramwells_precision_test_kit/features/contact/presentation/contact_page.dart';
import 'package:bramwells_precision_test_kit/shared/foundation/app_failure.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/navigation/app_routes.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/app_theme.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_auth.dart';
import '../../../support/fake_project_repository.dart';
import '../../../support/test_configuration.dart';

final class _ControlledSender implements ContactSender {
  final messages = <ContactMessage>[];
  Completer<void> result = Completer<void>();

  @override
  Future<void> send(ContactMessage message) {
    messages.add(message);
    return result.future;
  }
}

void main() {
  final copy = AppCopy.english;

  Future<void> pumpPage(WidgetTester tester, {ContactSender? sender}) =>
      pumpConfiguredWidget(
        tester,
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: ContactPage(sender: sender),
        ),
      );

  testWidgets('missing form config shows a localized unavailable state', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text(copy.contactDentonBramwell), findsOneWidget);
    expect(find.text(copy.contactUnavailable), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  for (final signedIn in [false, true]) {
    testWidgets('configured Contact route opens with signedIn=$signedIn', (
      tester,
    ) async {
      final auth = FakeAuth(
        initialUser: signedIn
            ? FakeAuthUser(
                uid: 'contact-user',
                email: 'visitor@example.test',
                verified: true,
              )
            : null,
      );
      final repository = FakeProjectRepository();
      addTearDown(repository.dispose);
      final services = auth.services;
      await pumpConfiguredWidget(
        tester,
        FirebaseApplication(
          clock: clock,
          services: FirebaseServices(
            app: services.app,
            auth: services.auth,
            sessions: services.sessions,
            db: services.db,
            config: AppConfig.fromValues({
              'CONFIG_SCHEMA_VERSION': AppConfig.schemaVersion,
              'APP_ENV': 'dev',
              'WEB3FORMS_ACCESS_KEY': '00000000-0000-0000-0000-000000000001',
            }),
          ),
          repositoryForUser: (_) => repository,
        ),
      );
      Future<void> settle() => tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await settle();
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(navigator.pushNamed<void>(AppRoutes.contact));
      await settle();
      expect(find.text(copy.contactDentonBramwell), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
    });
  }

  testWidgets(
    'validates, blocks repeat sends, retains failed input, then clears on success',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sender = _ControlledSender();
      await pumpPage(tester, sender: sender);
      final send = find.widgetWithText(FilledButton, copy.contactSend);
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      expect(sender.messages, isEmpty);
      expect(find.text(copy.contactEmailInvalid), findsOneWidget);

      await tester.enterText(fields.at(0), 'Example');
      await tester.enterText(fields.at(1), 'visitor@example.test');
      await tester.enterText(fields.at(2), 'My message');
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      final busy = find.widgetWithText(FilledButton, copy.contactSending);
      expect(tester.widget<FilledButton>(busy).onPressed, isNull);
      expect(sender.messages.single.email, 'visitor@example.test');

      sender.result.completeError(const AppFailure(FailureKind.unavailable));
      await tester.pump();
      expect(find.text(copy.contactSendFailed), findsOneWidget);
      expect(find.text('My message'), findsOneWidget);

      sender.result = Completer<void>();
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pump();
      expect(sender.messages, hasLength(2));
      sender.result.complete();
      await tester.pump();
      expect(find.text(copy.contactSent), findsOneWidget);
      expect(find.text('My message'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
