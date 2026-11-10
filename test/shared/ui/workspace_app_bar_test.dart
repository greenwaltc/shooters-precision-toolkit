import 'dart:math';

import 'package:bramwells_precision_test_kit/features/auth/presentation/workspace_sign_out.dart';
import 'package:bramwells_precision_test_kit/features/contact/presentation/contact_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/data_matrix_page.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/widgets/results_view.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_page.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_back_button.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_brand_bar.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/tokens/app_headings.dart';
import 'package:bramwells_precision_test_kit/shared/ui/workspace_exit.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../support/fake_project_repository.dart';
import '../../support/test_configuration.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('workspace actions include sign-out on every page at $size', (
      tester,
    ) async {
      rootBundle.clear();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = ProjectStore(
        clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
        draftStorage: InMemoryProjectDraftStorage(),
        repository: FakeProjectRepository(),
        saveDebounce: Duration.zero,
      );
      await store.load();
      final project = await store.createProject();
      project.formModel.setProjectTitle('Sign-out test');
      project.formModel.setFactorDefinition(
        index: 0,
        name: 'Factor',
        firstState: 'A',
        secondState: 'B',
      );
      expect(await store.completeProjectSetup(), isTrue);
      for (
        var i = 0;
        i < project.formModel.sampleSizeOption.totalSamples;
        i++
      ) {
        project.matrixState['range_$i'] = '${i % 5 + 1}';
      }
      var signOuts = 0;
      await pumpConfiguredWidget(
        tester,
        Provider<WorkspaceExit>.value(
          value: WorkspaceSignOut(
            flush: store.flush,
            signOut: () async {
              signOuts++;
            },
          ),
          child: MyApp(
            clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
            config: testConfig(),
            random: Random(4729),
            projectStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await _expectSignOut(tester);
      await _expectDonations(tester);
      final logoHeight = tester.getSize(find.byType(AppBrandTitleLogo)).height;
      await _tapAction(tester, 'Contact');
      expect(find.byType(ContactPage), findsOneWidget);
      expect(tester.getSize(find.byType(AppBrandTitleLogo)).height, logoHeight);
      expect(
        find.textContaining(AppCopy.english.copyrightCredit),
        findsWidgets,
      );
      expect(find.textContaining('denton@'), findsNothing);
      Navigator.of(tester.element(find.byType(ContactPage))).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      await tester.tap(find.text('Sign-out test'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.byType(AnomrMatrix), findsOneWidget);
      if (size.width == 390) {
        _expectCompactProjectBanner(tester);
      }
      await _expectSignOut(tester);
      await _expectDonations(tester);
      await _tapAction(tester, 'Contact');
      expect(find.byType(ContactPage), findsOneWidget);
      expect(tester.getSize(find.byType(AppBrandTitleLogo)).height, logoHeight);
      expect(
        find.textContaining(AppCopy.english.copyrightCredit),
        findsWidgets,
      );
      expect(find.textContaining('denton@'), findsNothing);
      Navigator.of(tester.element(find.byType(ContactPage))).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await _tapAction(tester, 'Test Design');
      expect(find.byType(ProjectFormPage), findsOneWidget);
      if (size.width == 390) {
        _expectCompactProjectBanner(tester);
      }
      await _expectSignOut(tester);
      await _expectDonations(tester);
      await _tapAction(tester, 'Contact');
      expect(find.byType(ContactPage), findsOneWidget);
      expect(tester.getSize(find.byType(AppBrandTitleLogo)).height, logoHeight);
      expect(
        find.textContaining(AppCopy.english.copyrightCredit),
        findsWidgets,
      );
      expect(find.textContaining('denton@'), findsNothing);
      Navigator.of(tester.element(find.byType(ContactPage))).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      Navigator.of(tester.element(find.byType(ProjectFormPage))).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      await tester.ensureVisible(find.text('Results'));
      await tester.tap(find.text('Results'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.byType(ResultsView), findsOneWidget);
      if (size.width == 390) {
        _expectCompactProjectBanner(tester);
      }
      await _expectSignOut(tester);
      await _expectDonations(tester);
      await _tapAction(tester, 'Contact');
      expect(find.byType(ContactPage), findsOneWidget);
      expect(tester.getSize(find.byType(AppBrandTitleLogo)).height, logoHeight);
      expect(
        find.textContaining(AppCopy.english.copyrightCredit),
        findsWidgets,
      );
      expect(find.textContaining('denton@'), findsNothing);
      Navigator.of(tester.element(find.byType(ContactPage))).pop();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await _tapAction(tester, 'Sign out');
      expect(signOuts, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await pumpConfiguredWidget(tester, const SizedBox.shrink());
      store.dispose();
    });
  }
}

Future<void> _expectSignOut(WidgetTester tester) async {
  if (find.byTooltip('Sign out').evaluate().isNotEmpty) {
    expect(find.byTooltip('Sign out'), findsOneWidget);
  } else {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Sign out'), findsOneWidget);
    Navigator.of(tester.element(find.text('Sign out'))).pop();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final inline = find.byTooltip(label);
  if (inline.evaluate().isNotEmpty) {
    await tester.tap(inline);
  } else {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    await tester.tap(find.text(label));
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

Future<void> _expectDonations(WidgetTester tester) async {
  if (find.byTooltip('Donate').evaluate().isNotEmpty) {
    expect(find.byTooltip('Donate'), findsOneWidget);
  } else {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Donate'), findsOneWidget);
    Navigator.of(tester.element(find.text('Donate'))).pop();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }
}

void _expectCompactProjectBanner(WidgetTester tester) {
  final brand = find.byType(AppBrandTitle);
  final title = find.descendant(
    of: brand,
    matching: find.text(tester.widget<AppBrandTitle>(brand).label),
  );
  final context = tester.element(title);
  expect(tester.widget<Text>(title).style, AppHeadings.h4(context));
  expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);

  final back = tester.getRect(find.byType(AppBackButton));
  final logo = tester.getRect(find.byType(AppBrandTitleLogo));
  final donate = tester.getRect(find.widgetWithText(FilledButton, 'DONATE'));
  expect(logo.left - back.right, inInclusiveRange(0, 12));
  expect(tester.getRect(title).right, lessThan(donate.left));
}
