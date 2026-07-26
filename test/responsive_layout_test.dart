// Copyright (c) 2026 Denton M. Bramwell. All rights reserved.
// Use of this source code is governed by a proprietary license that can be
// found in the LICENSE file at the root of this project.
// Unauthorized use or reproduction of this source code is prohibited.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:bramwells_precision_test_kit/config/project_configuration.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/storage/project_storage.dart';
import 'package:bramwells_precision_test_kit/styles/chart/chart_scale.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/widgets/empty_results_state.dart';
import 'package:bramwells_precision_test_kit/widgets/range_entry_sheet.dart';

/// A worst-case cell context: four factors with long state names.
const _fourFactorEntry = RangeEntryContext(
  rowIndex: 16,
  replicateIndex: 4,
  initialValue: '0.482',
  factorStates: [
    FactorStateEntry(factorName: 'Primer brand', state: 'Standard'),
    FactorStateEntry(factorName: 'Powder charge', state: 'Reduced'),
    FactorStateEntry(factorName: 'Seating depth', state: 'Off the lands'),
    FactorStateEntry(factorName: 'Neck tension', state: 'Two thousandths'),
  ],
);

/// Viewports spanning the range of devices the app ships on.
const _viewports = <String, Size>{
  'foldable cover': Size(280, 653),
  'small phone': Size(320, 568),
  'phone': Size(390, 844),
  'phone landscape': Size(844, 390),
  'large phone': Size(430, 932),
  'tablet portrait': Size(768, 1024),
  'tablet landscape': Size(1024, 768),
  'desktop': Size(1440, 900),
};

/// Text scales exercised at each viewport: default and the app's clamp ceiling.
const _textScales = <double>[1.0, 1.6];

void main() {
  group('setup flow', () {
    for (final entry in _viewports.entries) {
      for (final textScale in _textScales) {
        final label = '${entry.key} @ ${textScale}x';

        testWidgets('$label: home and setup form lay out without overflow', (
          WidgetTester tester,
        ) async {
          _configureViewport(tester, size: entry.value, textScale: textScale);

          await _pumpApp(tester);
          _expectNoLayoutErrors(tester, '$label — home empty state');

          await _tapText(
            tester,
            ProjectConfiguration.current.uiCopy.createProjectLabel,
          );
          _expectNoLayoutErrors(tester, '$label — empty setup form');

          await _tapText(
            tester,
            'Test how four factors influence precision',
          );
          _expectNoLayoutErrors(tester, '$label — four-factor setup form');
        });
      }
    }
  });

  group('matrix and results', () {
    for (final entry in _viewports.entries) {
      for (final factorCount in <int>[1, 4]) {
        final label = '${entry.key} @ 1.6x, $factorCount-factor';

        testWidgets('$label: matrix and results lay out without overflow', (
          WidgetTester tester,
        ) async {
          _configureViewport(tester, size: entry.value, textScale: 1.6);

          await _pumpCompletedProject(tester, factorCount: factorCount);
          await _tapText(tester, 'Bench Rest Comparison');
          _expectNoLayoutErrors(tester, '$label — data matrix');

          await _tapText(tester, 'Show Results');
          expect(
            find.textContaining('Results'),
            findsWidgets,
            reason: 'should have navigated to the results page',
          );
          _expectNoLayoutErrors(tester, '$label — results page');
        });
      }
    }
  });

  group('modals', () {
    for (final entry in _viewports.entries) {
      testWidgets('${entry.key}: help instructions sheet lays out', (
        WidgetTester tester,
      ) async {
        _configureViewport(tester, size: entry.value, textScale: 1.6);

        await _pumpApp(tester);
        await _tapText(
          tester,
          ProjectConfiguration.current.uiCopy.createProjectLabel,
        );
        await _openHelpSheet(tester);

        expect(find.text('Help'), findsOneWidget);
        _expectNoLayoutErrors(tester, '${entry.key} — help sheet');
      });
    }

    testWidgets('export dialog lays out on a small phone at max text scale', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(320, 568), textScale: 1.6);

      await _pumpCompletedProject(tester);
      await _tapText(tester, 'Bench Rest Comparison');
      await _tapText(tester, 'Show Results');
      await _tapText(tester, 'Export');

      expect(find.text('Export Results'), findsOneWidget);
      _expectNoLayoutErrors(tester, 'export dialog');
    });

    // The mobile cell-entry sheet is the one surface the grid opens on touch
    // devices, and a four-factor design puts four state columns inside it.
    for (final entry in _viewports.entries) {
      testWidgets('${entry.key}: range entry sheet lays out', (
        WidgetTester tester,
      ) async {
        _configureViewport(tester, size: entry.value, textScale: 1.6);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showRangeEntrySheet(
                    context,
                    entry: _fourFactorEntry,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Enter Group Size'), findsOneWidget);
        _expectNoLayoutErrors(tester, '${entry.key} — range entry sheet');
      });
    }

    // The sheet auto-focuses its text field, so the keyboard is up whenever it
    // is on screen. Landscape leaves very little room once it appears.
    testWidgets('range entry sheet lays out behind an open keyboard', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(844, 390), textScale: 1.6);
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showRangeEntrySheet(context, entry: _fourFactorEntry),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      _expectNoLayoutErrors(tester, 'range entry sheet with keyboard');
    });

    testWidgets('delete confirmation lays out on a small phone', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(320, 568), textScale: 1.6);

      await _pumpCompletedProject(tester);
      final deleteIcon = find.byIcon(Icons.delete_outline);
      await tester.ensureVisible(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Delete project?'), findsOneWidget);
      _expectNoLayoutErrors(tester, 'delete confirmation dialog');
    });

    testWidgets('app-bar overflow menu lays out on a small phone at max text scale', (
      WidgetTester tester,
    ) async {
      _configureViewport(tester, size: const Size(320, 568), textScale: 1.6);

      await _pumpCompletedProject(tester);
      await _tapText(tester, 'Bench Rest Comparison');

      final menu = find.byIcon(Icons.menu);
      expect(menu, findsOneWidget);
      await tester.tap(menu);
      await tester.pumpAndSettle();

      expect(find.text('Instructions'), findsWidgets);
      expect(find.text('Projects'), findsWidgets);
      expect(find.text('Project setup'), findsOneWidget);
      _expectNoLayoutErrors(tester, 'app-bar overflow menu');
    });
  });

  group('empty states', () {
    for (final entry in _viewports.entries) {
      testWidgets('${entry.key}: results empty state lays out', (
        WidgetTester tester,
      ) async {
        _configureViewport(tester, size: entry.value, textScale: 1.6);

        await tester.pumpWidget(
          const MaterialApp(
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
        await tester.pumpWidget(
          MaterialApp(
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
      final magnified = scales[1.6]!;
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
    _configureViewport(tester, size: const Size(320, 568), textScale: 1.6);

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
  final store = ProjectStore(storage: InMemoryProjectStorage());
  await store.load();
  await tester.pumpWidget(MyApp(projectStore: store));
  await tester.pumpAndSettle();
}

/// Boots the app with one fully configured project whose matrix cells are
/// already populated, so the results page can be reached in a single tap.
Future<void> _pumpCompletedProject(
  WidgetTester tester, {
  int factorCount = 1,
}) async {
  final store = ProjectStore(storage: InMemoryProjectStorage());
  await store.load();

  final project = await store.createProject();
  final model = project.formModel;
  model.setProjectTitle('Bench Rest Comparison');
  model.setExperimentStructure(
    ExperimentStructure.values.firstWhere(
      (structure) => structure.factorCount == factorCount,
    ),
  );
  for (var index = 0; index < factorCount; index++) {
    model.setFactorDefinition(
      index: index,
      name: 'Factor ${index + 1} name',
      firstState: 'State A${index + 1}',
      secondState: 'State B${index + 1}',
    );
  }
  expect(await store.completeProjectSetup(), isTrue);

  for (
    var index = 0;
    index < model.sampleSizeOption.totalSamples;
    index++
  ) {
    project.matrixState['range_$index'] = '${index % 5 + 1}';
  }

  await tester.pumpWidget(MyApp(projectStore: store));
  await tester.pumpAndSettle();
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
  final finder =
      buttonFinder.evaluate().isNotEmpty ? buttonFinder.first : textFinder.first;

  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Opens help from the app-bar Instructions control, or the mobile overflow
/// menu when actions are collapsed.
Future<void> _openHelpSheet(WidgetTester tester) async {
  final instructions = find.text('Instructions');
  if (instructions.evaluate().isNotEmpty) {
    await tester.tap(instructions.first);
    await tester.pumpAndSettle();
    return;
  }

  final menu = find.byIcon(Icons.menu);
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu.first);
    await tester.pumpAndSettle();
    final menuInstructions = find.text('Instructions');
    expect(menuInstructions, findsWidgets);
    await tester.tap(menuInstructions.last);
    await tester.pumpAndSettle();
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
