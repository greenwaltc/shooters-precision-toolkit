import 'dart:async';
import 'dart:math';

import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/matrix/widgets/grid_scroll_cue.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/project_store.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/results/widgets/empty_results_state.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/shared/l10n/app_copy.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_brand_bar.dart';
import 'package:bramwells_precision_test_kit/shared/ui/app_copyright_footer.dart';
import 'package:bramwells_precision_test_kit/shared/ui/product_configuration.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/chart/chart_scale.dart';
import 'package:bramwells_precision_test_kit/shared/ui/theme/tokens/app_headings.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show LogicalKeyboardKey, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../../../../support/fake_project_repository.dart';
import '../../../../support/test_configuration.dart';

// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

/// Viewports spanning the range of devices the app ships on.
const _viewports = <String, Size>{
  'foldable cover': Size(280, 653),
  'small phone': Size(320, 568),
  'phone': Size(390, 844),
  'phone landscape': Size(844, 390),
  'large phone': Size(430, 932),
  'below mobile breakpoint': Size(719, 900),
  'at mobile breakpoint': Size(720, 900),
  'above mobile breakpoint': Size(721, 900),
  'below desktop breakpoint': Size(1023, 900),
  'above desktop breakpoint': Size(1025, 900),
  'tablet portrait': Size(768, 1024),
  'tablet landscape': Size(1024, 768),
  'desktop': Size(1440, 900),
};

/// Text scales exercised at each viewport: default and 200% accessibility scaling.
const _textScales = <double>[1.0, 2.0];

void main() {
  testWidgets(
    'desktop matrix keeps its viewport through saving and retry feedback',
    (tester) async {
      _configureViewport(tester, size: const Size(1440, 900), textScale: 1);
      await _pumpCompletedProject(tester, factorCount: 4);
      await _tapText(tester, 'Bench Rest Comparison');
      final grid = find.byType(PlutoGrid);
      final original = tester.getRect(grid);
      expect(original.top, lessThan(200));
      expect(original.height, greaterThan(550));
      expect(original.width, greaterThanOrEqualTo(840));
      final store = tester.widget<MyApp>(find.byType(MyApp)).projectStore!;
      final repository = store.repository as FakeProjectRepository;
      final barrier = Completer<void>();
      repository.saveBarrier = barrier.future;
      store.selectedProject!.formModel.setProjectTitle('Desktop layout check');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();
      expect(
        find.text('Saving…'),
        findsOneWidget,
        reason: 'The pending repository request must expose saving feedback.',
      );
      expect(tester.getRect(grid), original);
      repository.saveFailure = StateError('Simulated network failure');
      barrier.complete();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('Retry save'), findsOneWidget);
      expect(tester.getRect(grid), original);
      repository.saveFailure = null;
      await store.saveSelectedProject();
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('Saved'), findsOneWidget);
      expect(tester.getRect(grid), original);
      _expectNoLayoutErrors(tester, 'desktop save feedback');
    },
  );

  for (final factorCount in [1, 4]) {
    testWidgets(
      'live $factorCount-factor matrix refits across desktop and tablet widths',
      (tester) async {
        _configureViewport(tester, size: const Size(1440, 900), textScale: 1);
        await _pumpCompletedProject(tester, factorCount: factorCount);
        await _tapText(tester, 'Bench Rest Comparison');
        final grid = find.byType(PlutoGrid);
        final manager = tester.state<PlutoGridState>(grid).stateManager;
        final store = tester.widget<MyApp>(find.byType(MyApp)).projectStore!;
        final originalValues = Map.of(store.selectedProject!.matrixState);
        expect(manager.columns.map((column) => column.field).toList(), [
          'row',
          if (factorCount > 1) 'group',
          for (var index = 0; index < factorCount; index++) 'factor_$index',
          'range',
        ]);
        for (final width in [
          1920.0,
          1440.0,
          1100.0,
          1024.0,
          1000.0,
          900.0,
          800.0,
          720.0,
          900.0,
          1024.0,
          1440.0,
        ]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 5),
          );
          expect(
            tester.state<PlutoGridState>(grid).stateManager,
            same(manager),
          );
          if (width >= 1024) {
            final gridBounds = tester.getRect(grid);
            final results = find.widgetWithText(FilledButton, 'Results');
            final clear = find.ancestor(
              of: find.text('Clear'),
              matching: find.byWidgetPredicate(
                (widget) => widget is OutlinedButton,
              ),
            );
            expect(
              tester.getTopRight(results).dx,
              closeTo(gridBounds.right, 1),
              reason:
                  'Results aligns with the matrix right edge at width=$width',
            );
            expect(
              tester.getTopLeft(find.text('Data matrix')).dx,
              closeTo(gridBounds.left, 1),
            );
            expect(
              tester.getCenter(find.byType(Switch)).dx,
              lessThan(tester.getCenter(clear).dx),
            );
            expect(
              tester.getCenter(clear).dx,
              lessThan(tester.getCenter(results).dx),
            );
            expect(
              tester.getCenter(clear).dy,
              closeTo(tester.getCenter(results).dy, 1),
            );
            expect(
              tester.getCenter(find.byType(Switch)).dy,
              closeTo(tester.getCenter(results).dy, 1),
            );
          } else {
            _expectCompactMatrixActions(tester, tester.getRect(grid));
          }
          expect(
            manager.configuration.style.rowHeight,
            36,
            reason: 'width=$width',
          );
          final scroll = manager.scroll.bodyRowsHorizontal!.position;
          final minimumWidth = manager.columns.fold<double>(
            0,
            (sum, column) =>
                sum +
                (column.suppressedAutoSize ? column.width : column.minWidth),
          );
          // Many-factor grids may genuinely exceed a narrow viewport. Only
          // their minimum readable widths may cause horizontal scrolling.
          final requiredOverflow = minimumWidth > scroll.viewportDimension
              ? minimumWidth - scroll.viewportDimension
              : 0.0;
          expect(
            scroll.maxScrollExtent,
            lessThanOrEqualTo(requiredOverflow + 1),
            reason: 'Unnecessary horizontal overflow at width=$width',
          );
          expect(
            tester.getBottomRight(find.byType(AppCopyrightFooter)).dy,
            900,
            reason:
                'No reserved status band below the copyright at width=$width',
          );
          expect(store.selectedProject!.matrixState, originalValues);
          _expectNoLayoutErrors(tester, 'live resize at width=$width');
        }
      },
    );
  }

  for (final (width, scrolls) in [(680.0, false), (390.0, true)]) {
    testWidgets(
      'mobile matrix only scrolls horizontally when contents exceed $width px',
      (tester) async {
        _configureViewport(tester, size: Size(width, 844), textScale: 1);
        await _pumpCompletedProject(tester, factorCount: 4, shortLabels: true);
        await _tapText(tester, 'Bench Rest Comparison');
        final manager = tester
            .state<PlutoGridState>(find.byType(PlutoGrid))
            .stateManager;
        final horizontal = manager.scroll.bodyRowsHorizontal!;
        expect(
          horizontal.position.maxScrollExtent > 1,
          scrolls,
          reason:
              'Viewport ${horizontal.position.viewportDimension}, '
              'overflow ${horizontal.position.maxScrollExtent}, '
              'columns ${manager.columns.map((column) => column.width)}',
        );
        final contentWidth = manager.columns.fold<double>(
          0,
          (sum, column) => sum + column.width,
        );
        expect(
          horizontal.position.maxScrollExtent,
          closeTo(
            max(0, contentWidth - horizontal.position.viewportDimension),
            1,
          ),
        );
        final label = tester.renderObject<RenderParagraph>(find.text('F1'));
        expect(label.didExceedMaxLines, isFalse);
        final value = tester.renderObject<RenderParagraph>(
          find.text('A').hitTestable().first,
        );
        expect(
          value.size.width,
          greaterThanOrEqualTo(value.getMaxIntrinsicWidth(double.infinity)),
        );
        horizontal.jumpTo(horizontal.position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(find.text('Group Size').hitTestable(), findsOneWidget);
        _expectNoLayoutErrors(tester, 'mobile matrix content fit');
      },
    );
  }

  for (final size in [
    const Size(280, 653),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'mobile matrix toolbar at $size and $textScale keeps one action row',
        (tester) async {
          _configureViewport(tester, size: size, textScale: textScale);
          await _pumpCompletedProject(tester);
          await _tapText(tester, 'Bench Rest Comparison');
          final grid = find.byType(PlutoGrid);
          final gridBounds = tester.getRect(grid);
          _expectCompactMatrixActions(tester, gridBounds);
          expect(find.text('Yes'), findsNothing);
          expect(find.text('No'), findsNothing);
          final credit = find.text(AppCopyrightFooter.noticeText);
          final footerText = tester.widget<Text>(credit);
          expect(footerText.maxLines, 1);
          expect(footerText.softWrap, false);
          expect(footerText.style!.color, Colors.black);
          final footer = find.byType(AppCopyrightFooter);
          final background = find.descendant(
            of: footer,
            matching: find.byWidgetPredicate(
              (widget) => widget is Material && widget.color == Colors.white,
            ),
          );
          expect(background, findsOneWidget);
          expect(
            tester.getRect(footer).height,
            closeTo(tester.getRect(credit).height, 0.1),
          );
          expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 56);
          expect(gridBounds.height, greaterThan(100));
          final original = tester.getRect(grid);
          final store = tester.widget<MyApp>(find.byType(MyApp)).projectStore!;
          final repository = store.repository as FakeProjectRepository;
          final barrier = Completer<void>();
          repository.saveBarrier = barrier.future;
          store.selectedProject!.formModel.setProjectTitle(
            'Phone layout check',
          );
          await tester.pump(const Duration(milliseconds: 10));
          await tester.pump();
          expect(tester.getRect(grid), original);
          barrier.complete();
          await tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 5),
          );
          expect(tester.getRect(grid), original);
          _expectNoLayoutErrors(tester, 'mobile matrix toolbar');
        },
      );
    }
  }

  for (final (size, keyboardHeight, textScale) in [
    (const Size(390, 844), 430.0, 1.0),
    (const Size(844, 390), 220.0, 1.0),
    (const Size(320, 568), 310.0, 2.0),
  ]) {
    testWidgets(
      'bottom mobile matrix cell stays visible while editing at $size',
      (tester) async {
        _configureViewport(tester, size: size, textScale: textScale);
        await _pumpCompletedProject(tester, factorCount: 4);
        await _tapText(tester, 'Bench Rest Comparison');
        final grid = find.byType(PlutoGrid);
        final manager = tester.state<PlutoGridState>(grid).stateManager;
        final vertical = manager.scroll.bodyRowsVertical!;
        final horizontal = manager.scroll.bodyRowsHorizontal!;
        vertical.jumpTo(vertical.position.maxScrollExtent);
        horizontal.jumpTo(horizontal.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final cell = find.byKey(
          ValueKey('matrix-cell-${manager.rows.length - 1}-range'),
        );
        final editor = find.descendant(
          of: cell,
          matching: find.byType(TextField),
        );
        await tester.ensureVisible(editor);
        await tester.pumpAndSettle();
        await tester.tap(editor);
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
        expect(
          tester.widget<TextField>(editor).keyboardType,
          TextInputType.number,
        );
        expect(tester.testTextInput.isVisible, isTrue);
        expect(find.byType(BottomSheet), findsNothing);

        tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.state<PlutoGridState>(grid).stateManager, same(manager));
        expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isTrue);
        // The caret handle can sit over the center of a narrow cell.
        expect(
          const [
            Alignment.center,
            Alignment(-0.75, 0),
            Alignment(0.75, 0),
          ].any((point) => editor.hitTestable(at: point).evaluate().isNotEmpty),
          isTrue,
        );
        expect(
          tester.getRect(editor).bottom,
          lessThanOrEqualTo(size.height - keyboardHeight),
        );
        final outline = find.descendant(
          of: cell,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is DecoratedBox &&
                widget.position == DecorationPosition.foreground &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).border != null,
          ),
        );
        expect(outline, findsOneWidget);
        expect(tester.getRect(outline), tester.getRect(cell));

        final handled = await tester.sendKeyDownEvent(
          LogicalKeyboardKey.digit4,
          character: '4',
        );
        await tester.sendKeyUpEvent(LogicalKeyboardKey.digit4);
        expect(
          handled,
          isFalse,
          reason: 'The keypad digit must reach text input.',
        );
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: '42',
            selection: TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pumpAndSettle();
        expect(manager.rows.last.cells['range']!.value, '42');
        final storage = manager.rows.last.cells['storage']!.value;
        final store = tester.widget<MyApp>(find.byType(MyApp)).projectStore!;
        expect(store.selectedProject!.matrixState['range_$storage'], '42');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(editor).focusNode!.hasFocus, isFalse);
        expect(outline, findsNothing);
        _expectNoLayoutErrors(tester, 'mobile matrix with keyboard');
      },
    );
  }

  group('setup flow', () {
    testWidgets('mobile keyboard gives the form all remaining space', (
      tester,
    ) async {
      _configureViewport(tester, size: const Size(390, 844), textScale: 1);
      await _pumpApp(tester);
      await _tapText(
        tester,
        ProjectConfiguration.defaults.uiCopy.createProjectLabel,
      );
      final form = find.byType(ProjectForm);
      final scroll = find.descendant(
        of: form,
        matching: find.byType(SingleChildScrollView),
      );
      final cues = find.descendant(
        of: form,
        matching: find.byType(GridScrollCue),
      );
      final title = find
          .descendant(of: form, matching: find.byType(TextFormField))
          .first;
      final before = tester.getSize(scroll).height;
      final submit = find.descendant(of: scroll, matching: find.text('Submit'));
      expect(submit, findsOneWidget);
      expect(submit.hitTestable(), findsNothing);

      await tester.enterText(title, 'Keyboard test');
      const keyboardHeight = 330.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      expect(submit.hitTestable(), findsNothing);
      expect(cues, findsNothing);
      expect(
        tester.getSize(scroll).height,
        greaterThan(before - keyboardHeight),
      );
      expect(find.text('Keyboard test'), findsWidgets);
      _expectNoLayoutErrors(tester, 'Test Design with keyboard');

      tester.view.resetViewInsets();
      await tester.pump();
      await tester.ensureVisible(submit);
      await tester.pump();
      expect(submit.hitTestable(), findsOneWidget);
    });

    for (final entry in _viewports.entries) {
      for (final textScale in _textScales) {
        final label = '${entry.key} @ ${textScale}x';

        testWidgets('$label: home and setup form lay out without overflow', (
          WidgetTester tester,
        ) async {
          _configureViewport(tester, size: entry.value, textScale: textScale);

          await _pumpApp(tester);
          _expectNoLayoutErrors(tester, '$label — home empty state');
          final homeLogo = find.descendant(
            of: find.byType(AppProjectsBannerTitle),
            matching: find.byType(Image),
          );
          expect(tester.getTopLeft(homeLogo).dx, closeTo(16, 1));

          await _tapText(
            tester,
            ProjectConfiguration.defaults.uiCopy.createProjectLabel,
          );
          _expectNoLayoutErrors(tester, '$label — empty setup form');

          await _tapText(tester, 'Test how four factors influence precision');
          _expectNoLayoutErrors(tester, '$label — four-factor setup form');
        });
      }
    }
  });

  testWidgets('desktop project title switches artwork before shortening', (
    tester,
  ) async {
    const name = 'Comparing several loads in variable conditions';
    _configureViewport(tester, size: const Size(2400, 900), textScale: 1);
    await _pumpCompletedProject(tester, projectName: name);
    await _tapText(tester, name);
    final brand = find.byType(AppBrandTitle);
    final title = find.descendant(of: brand, matching: find.text(name));
    final image = find.descendant(of: brand, matching: find.byType(Image));
    String asset() =>
        (tester.widget<Image>(image).image as AssetImage).assetName;
    double fontSize() => tester.widget<Text>(title).style!.fontSize!;
    bool isTruncated() =>
        tester.renderObject<RenderParagraph>(title).didExceedMaxLines;
    final headingSize = AppHeadings.h2(tester.element(title))!.fontSize!;

    expect(asset(), AppBrandAssets.bannerLogo);
    expect(fontSize(), headingSize);
    expect(isTruncated(), isFalse);

    tester.view.physicalSize = const Size(2100, 900);
    await tester.pump();
    expect(asset(), AppBrandAssets.compactIcon);
    expect(fontSize(), headingSize);
    expect(isTruncated(), isFalse);

    tester.view.physicalSize = const Size(1024, 900);
    await tester.pump();
    expect(asset(), AppBrandAssets.compactIcon);
    expect(fontSize(), lessThan(headingSize));
    expect(tester.widget<Text>(title).overflow, TextOverflow.ellipsis);
    expect(isTruncated(), isTrue);
    _expectNoLayoutErrors(tester, 'constrained desktop project banner');
  });

  group('matrix and results', () {
    for (final entry in _viewports.entries) {
      for (final factorCount in <int>[1, 4]) {
        final label = '${entry.key} @ 2.0x, $factorCount-factor';

        testWidgets('$label: matrix and results lay out without overflow', (
          WidgetTester tester,
        ) async {
          _configureViewport(tester, size: entry.value, textScale: 2.0);

          await _pumpCompletedProject(tester, factorCount: factorCount);
          final homeLogoHeight = tester
              .getSize(find.byType(AppBrandTitleLogo))
              .height;
          if (entry.value.width >= 1024) {
            expect(homeLogoHeight, 72);
          }
          await _tapText(tester, 'Bench Rest Comparison');
          _expectNoLayoutErrors(tester, '$label — data matrix');
          final clear = tester.widget<OutlinedButton>(
            find.ancestor(
              of: find.text('Clear'),
              matching: find.byWidgetPredicate(
                (widget) => widget is OutlinedButton,
              ),
            ),
          );
          expect(
            clear.style?.side?.resolve({})?.color,
            clear.style?.foregroundColor?.resolve({}),
          );
          expect(
            tester.getSize(find.byType(AppBrandTitleLogo)).height,
            homeLogoHeight,
          );

          await _tapText(tester, 'Results');
          expect(
            find.textContaining('Results'),
            findsWidgets,
            reason: 'should have navigated to the results page',
          );
          _expectNoLayoutErrors(tester, '$label — results page');
          if (entry.value.width >= 1024) {
            expect(find.text('Saved'), findsNothing);
          }
          expect(
            tester.getSize(find.byType(AppBrandTitleLogo)).height,
            homeLogoHeight,
          );
        });
      }
    }
  });

  group('modals', () {
    for (final entry in _viewports.entries) {
      testWidgets('${entry.key}: help instructions sheet lays out', (
        WidgetTester tester,
      ) async {
        _configureViewport(tester, size: entry.value, textScale: 2.0);

        await _pumpApp(tester);
        await _tapText(
          tester,
          ProjectConfiguration.defaults.uiCopy.createProjectLabel,
        );
        await _openHelpSheet(tester);

        expect(find.text('Help'), findsOneWidget);
        _expectNoLayoutErrors(tester, '${entry.key} — help sheet');
      });
    }

    testWidgets('export dialog lays out on a small phone at max text scale', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(320, 568), textScale: 2.0);

      await _pumpCompletedProject(tester);
      await _tapText(tester, 'Bench Rest Comparison');
      await _tapText(tester, 'Results');
      await _tapText(tester, 'Export');

      expect(find.text('Export Results'), findsOneWidget);
      _expectNoLayoutErrors(tester, 'export dialog');
    });

    testWidgets('delete confirmation lays out on a small phone', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(320, 568), textScale: 2.0);

      await _pumpCompletedProject(tester);
      final deleteIcon = find.byIcon(Icons.delete_outline);
      await tester.ensureVisible(deleteIcon);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );

      expect(find.text('Delete project?'), findsOneWidget);
      _expectNoLayoutErrors(tester, 'delete confirmation dialog');
    });

    testWidgets(
      'app-bar overflow menu lays out on a small phone at max text scale',
      (WidgetTester tester) async {
        _configureViewport(tester, size: const Size(320, 568), textScale: 2.0);

        await _pumpCompletedProject(tester);
        await _tapText(tester, 'Bench Rest Comparison');

        final menu = find.byIcon(Icons.menu);
        expect(menu, findsOneWidget);
        await tester.tap(menu);
        await tester.pumpAndSettle(
          const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 5),
        );

        expect(find.text('Instructions'), findsWidgets);
        expect(find.text('Projects'), findsWidgets);
        expect(find.text('Test Design'), findsOneWidget);
        _expectNoLayoutErrors(tester, 'app-bar overflow menu');
      },
    );
  });

  group('empty states', () {
    for (final entry in _viewports.entries) {
      testWidgets('${entry.key}: results empty state lays out', (
        WidgetTester tester,
      ) async {
        _configureViewport(tester, size: entry.value, textScale: 2.0);

        await pumpConfiguredWidget(
          tester,
          const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SafeArea(child: EmptyResultsState())),
          ),
        );

        expect(find.text('No group size data available'), findsOneWidget);
        _expectNoLayoutErrors(tester, '${entry.key} — results empty state');
      });
    }
  });

  group('chart scale', () {
    testWidgets('axis reserves grow with the text-scale preference', (
      WidgetTester tester,
    ) async {
      final scales = <double, ChartScale>{};
      for (final textScale in _textScales) {
        _configureViewport(
          tester,
          size: const Size(1440, 900),
          textScale: textScale,
        );
        await pumpConfiguredWidget(
          tester,
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LayoutBuilder(
              builder: (context, constraints) {
                scales[textScale] = ChartScale.of(context, constraints);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      final normal = scales[1.0]!;
      final magnified = scales[2.0]!;
      expect(magnified.leftAxisReserve, greaterThan(normal.leftAxisReserve));
      expect(
        magnified.bottomStateLabelReserve,
        greaterThan(normal.bottomStateLabelReserve),
      );
      expect(magnified.chartHeight, greaterThan(normal.chartHeight));
    });

    test('export scale ignores text magnification', () {
      expect(ChartScale.export.textScale, 1.0);
    });
  });

  testWidgets('home project list lays out on a small phone at max text scale', (
    WidgetTester tester,
  ) async {
    _configureViewport(tester, size: const Size(320, 568), textScale: 2.0);

    await _pumpCompletedProject(tester);

    expect(find.byType(ListTile), findsOneWidget);
    _expectNoLayoutErrors(tester, 'home project list');
  });
}

void _configureViewport(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) {
  // Each test runs in its own async zone, so a bundle entry cached by an
  // earlier test resolves to a future that never delivers here.
  rootBundle.clear();

  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;

  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Future<void> _pumpApp(WidgetTester tester) async {
  final store = ProjectStore(
    clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
    draftStorage: InMemoryProjectDraftStorage(),
    repository: FakeProjectRepository(),
    saveDebounce: Duration.zero,
  );
  addTearDown(store.dispose);
  await store.load();
  await pumpConfiguredWidget(
    tester,
    MyApp(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      config: testConfig(),
      random: Random(4729),
      projectStore: store,
    ),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

/// Boots the app with one fully configured project whose matrix cells are
/// already populated, so the results page can be reached in a single tap.
void _expectCompactMatrixActions(WidgetTester tester, Rect gridBounds) {
  final clear = tester.getRect(find.widgetWithText(OutlinedButton, 'Clear'));
  final export = tester.getRect(find.widgetWithText(OutlinedButton, 'Export'));
  final results = tester.getRect(find.widgetWithText(FilledButton, 'Results'));
  final toggle = tester.getRect(find.byType(Switch));
  final title = tester.getRect(find.text('Data matrix'));

  expect(clear.center.dy, closeTo(export.center.dy, 1));
  expect(export.center.dy, closeTo(results.center.dy, 1));
  expect(clear.left, closeTo(gridBounds.left, 1));
  expect(results.right, closeTo(gridBounds.right, 1));
  expect(clear.right, lessThan(export.left));
  expect(export.right, lessThan(results.left));
  expect(clear.height, greaterThanOrEqualTo(48));
  expect(results.height, greaterThanOrEqualTo(48));
  expect(toggle.right, closeTo(gridBounds.right, 1));
  expect(title.center.dy, closeTo(toggle.center.dy, 1));
  expect(clear.top, greaterThanOrEqualTo(max(title.bottom, toggle.bottom)));
  expect(results.bottom, lessThanOrEqualTo(gridBounds.top));
}

Future<void> _pumpCompletedProject(
  WidgetTester tester, {
  int factorCount = 1,
  String projectName = 'Bench Rest Comparison',
  bool shortLabels = false,
}) async {
  final store = ProjectStore(
    clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
    draftStorage: InMemoryProjectDraftStorage(),
    repository: FakeProjectRepository(),
    saveDebounce: Duration.zero,
  );
  addTearDown(store.dispose);
  await store.load();

  final project = await store.createProject();
  final model = project.formModel;
  model.setProjectTitle(projectName);
  model.setExperimentStructure(
    ExperimentStructure.values.firstWhere(
      (structure) => structure.factorCount == factorCount,
    ),
  );
  for (var index = 0; index < factorCount; index++) {
    model.setFactorDefinition(
      index: index,
      name: shortLabels ? 'F${index + 1}' : 'Factor ${index + 1} name',
      firstState: shortLabels ? 'A' : 'State A${index + 1}',
      secondState: shortLabels ? 'B' : 'State B${index + 1}',
    );
  }
  expect(await store.completeProjectSetup(), isTrue);

  for (var index = 0; index < model.sampleSizeOption.totalSamples; index++) {
    project.matrixState['range_$index'] = '${index % 5 + 1}';
  }

  await pumpConfiguredWidget(
    tester,
    MyApp(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      config: testConfig(),
      random: Random(4729),
      projectStore: store,
    ),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  // Let the store's debounced save timer fire so it cannot outlive the test.
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _tapText(WidgetTester tester, String label) async {
  final textFinder = find.text(label);
  expect(textFinder, findsWidgets, reason: 'expected text "$label" on screen');

  final buttonFinder = find.ancestor(
    of: textFinder.first,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is FilledButton ||
          widget is TextButton ||
          widget is OutlinedButton,
    ),
  );
  final finder = buttonFinder.evaluate().isNotEmpty
      ? buttonFinder.first
      : textFinder.first;

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
  await tester.tap(finder);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

/// Opens help from the Instructions control (app-bar button, Projects FAB, or
/// the mobile overflow menu when actions are collapsed).
Future<void> _openHelpSheet(WidgetTester tester) async {
  for (final finder in <Finder>[
    find.text('Instructions'),
    find.byTooltip('Instructions'),
    find.byIcon(Icons.menu_book_outlined),
  ]) {
    if (finder.evaluate().isEmpty) {
      continue;
    }
    await tester.tap(finder.first);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    return;
  }

  final menu = find.byIcon(Icons.menu);
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu.first);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    final menuInstructions = find.text('Instructions');
    expect(menuInstructions, findsWidgets);
    await tester.tap(menuInstructions.last);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    return;
  }

  fail('No help control found in the current layout.');
}

/// Fails with the offending surface named when a layout/paint error (such as
/// a `RenderFlex` overflow) was reported while rendering.
void _expectNoLayoutErrors(WidgetTester tester, String surface) {
  final exception = tester.takeException();
  expect(exception, isNull, reason: 'Layout error on $surface: $exception');
}
