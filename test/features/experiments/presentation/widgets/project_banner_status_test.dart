import 'dart:async';

import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/widgets/project_save_status.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_brand_bar.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_copyright_footer.dart';
import 'package:bramwells_precision_test_kit/shared/ui/navigation/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/matrix_test_fixture.dart';
import '../../../../support/test_configuration.dart';

void main() {
  for (final size in [
    const Size(280, 653),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1440, 900),
  ]) {
    testWidgets(
      'project status stays beside the name and outside the footer at $size',
      (tester) async {
        final (store, _) = await pumpMatrixFixture(
          tester,
          saveDebounce: const Duration(days: 1),
        );
        tester.view.physicalSize = size;
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        final project = store.selectedProject!;
        final backend = store.repository as FakeProjectRepository;
        await store.saveSelectedProject();
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        for (final route in [AppRoutes.anomrMatrix, AppRoutes.projectForm]) {
          if (route == AppRoutes.projectForm) {
            unawaited(
              Navigator.of(
                tester.element(find.byType(PlutoGrid)),
              ).pushNamed(route),
            );
            await tester.pumpAndSettle(
              const Duration(milliseconds: 100),
              EnginePhase.sendSemanticsUpdate,
              const Duration(seconds: 5),
            );
          }
          _expectBannerStatus(tester, project.displayName);
          expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
          final appBarHeight = tester.getSize(find.byType(AppBar)).height;
          final footerHeight = tester
              .getSize(find.byType(AppCopyrightFooter))
              .height;
          expect(footerHeight, lessThan(32));
          final gridBounds = route == AppRoutes.anomrMatrix
              ? tester.getRect(find.byType(PlutoGrid))
              : null;

          project.formModel.setRiskLevel(
            RiskLevel.values.firstWhere(
              (level) => level != project.formModel.riskLevel,
            ),
          );
          await tester.pump();
          _expectBannerStatus(tester, project.displayName);
          expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

          final barrier = Completer<void>();
          backend.saveBarrier = barrier.future;
          final save = store.saveSelectedProject();
          await tester.pump();
          await tester.pump();
          expect(find.byIcon(Icons.sync), findsOneWidget);
          barrier.complete();
          await save;
          backend.saveBarrier = null;
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 5),
          );
          expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
          expect(tester.getSize(find.byType(AppBar)).height, appBarHeight);
          expect(
            tester.getSize(find.byType(AppCopyrightFooter)).height,
            footerHeight,
          );
          if (gridBounds != null) {
            expect(tester.getRect(find.byType(PlutoGrid)), gridBounds);
          }
          expect(tester.takeException(), isNull);
        }
        // The banner retains retry functionality even in icon-only mobile mode.
        project.formModel.setRiskLevel(
          RiskLevel.values.firstWhere(
            (level) => level != project.formModel.riskLevel,
          ),
        );
        backend.saveFailure = StateError('offline');
        await expectLater(store.saveSelectedProject(), throwsStateError);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        final retry = find.descendant(
          of: find.byType(ProjectSaveStatus),
          matching: find.byWidgetPredicate(
            (w) => w is TextButton || w is IconButton,
          ),
        );
        backend.saveFailure = null;
        await tester.tap(retry);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );
        expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
        expect(tester.takeException(), isNull);
        await pumpConfiguredWidget(tester, const SizedBox.shrink());
      },
    );
  }
}

void _expectBannerStatus(WidgetTester tester, String name) {
  final status = find.byType(ProjectSaveStatus);
  expect(status, findsOneWidget);
  expect(
    find.descendant(of: find.byType(AppBrandTitle), matching: status),
    findsOneWidget,
  );
  expect(
    find.descendant(of: find.byType(AppCopyrightFooter), matching: status),
    findsNothing,
  );
  final heading = find.descendant(
    of: find.byType(AppBrandTitle),
    matching: find.text(name),
  );
  expect(
    tester.getRect(status).left,
    greaterThanOrEqualTo(tester.getRect(heading).right + 7),
  );
  expect(tester.getCenter(status).dy, closeTo(tester.getCenter(heading).dy, 1));
}
