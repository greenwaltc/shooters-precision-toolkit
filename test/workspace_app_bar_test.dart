import 'package:bramwells_precision_test_kit/auth/workspace_sign_out.dart';
import 'package:bramwells_precision_test_kit/main.dart';
import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/storage/project_storage.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_matrix.dart';
import 'package:bramwells_precision_test_kit/widgets/anomr_results/widgets/results_view.dart';
import 'package:bramwells_precision_test_kit/widgets/project_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in [const Size(320, 568), const Size(1440, 900)]) {
    testWidgets('workspace actions include sign-out on every page at $size', (
      tester,
    ) async {
      rootBundle.clear();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final store = ProjectStore(storage: InMemoryProjectStorage());
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
      await tester.pumpWidget(
        Provider<WorkspaceSignOut>.value(
          value: WorkspaceSignOut(
            flush: store.flush,
            signOut: () async {
              signOuts++;
            },
          ),
          child: MyApp(projectStore: store),
        ),
      );
      await tester.pumpAndSettle();
      await _expectSignOut(tester);

      await tester.tap(find.text('Sign-out test'));
      await tester.pumpAndSettle();
      expect(find.byType(AnomrMatrix), findsOneWidget);
      await _expectSignOut(tester);
      await _tapAction(tester, 'Project setup');
      expect(find.byType(ProjectFormPage), findsOneWidget);
      await _expectSignOut(tester);
      Navigator.of(tester.element(find.byType(ProjectFormPage))).pop();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Show Results'));
      await tester.tap(find.text('Show Results'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultsView), findsOneWidget);
      await _expectSignOut(tester);
      await _tapAction(tester, 'Sign out');
      expect(signOuts, 1);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }
}

Future<void> _expectSignOut(WidgetTester tester) async {
  if (find.byTooltip('Sign out').evaluate().isNotEmpty) {
    expect(find.byTooltip('Sign out'), findsOneWidget);
  } else {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out'), findsOneWidget);
    Navigator.of(tester.element(find.text('Sign out'))).pop();
    await tester.pumpAndSettle();
  }
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final inline = find.byTooltip(label);
  if (inline.evaluate().isNotEmpty) {
    await tester.tap(inline);
  } else {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
  }
  await tester.pumpAndSettle();
}
