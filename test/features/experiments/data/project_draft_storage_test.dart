import 'package:bramwells_precision_test_kit/features/experiments/data/project_draft_storage.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/saved_project.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('drafts freeze mutable form and matrix values', () {
    final project = _project();
    project.matrixState['range_0'] = '1.5';
    final draft = ProjectDraft.capture(project, 4, 9);

    project.formModel.setProjectTitle('Changed later');
    project.matrixState['range_0'] = '2.5';

    expect(draft.project.displayName, 'Draft');
    expect(draft.project.matrixState['range_0'], '1.5');
    expect(draft.expectedRevision, 4);
    expect(draft.editCounter, 9);
  });

  test('acknowledgement cannot remove a newer or different draft', () async {
    final storage = InMemoryProjectDraftStorage();
    final project = _project();
    final acknowledged = ProjectDraft.capture(project, 3, 8);
    await storage.write(project.id, acknowledged);

    expect(
      await storage.removeIfMatches(
        project.id,
        ProjectDraft.capture(project, 3, 7),
      ),
      isFalse,
    );
    expect(
      await storage.removeIfMatches(
        project.id,
        ProjectDraft.capture(project, 2, 8),
      ),
      isFalse,
    );
    project.formModel.setProjectTitle('Different content');
    expect(
      await storage.removeIfMatches(
        project.id,
        ProjectDraft.capture(project, 3, 8),
      ),
      isFalse,
    );
    expect((await storage.readAll())[project.id]!.project.displayName, 'Draft');
    expect(await storage.removeIfMatches(project.id, acknowledged), isTrue);
    expect(await storage.readAll(), isEmpty);
  });

  test(
    'a replacement workspace cannot read the previous draft store',
    () async {
      final firstWorkspace = InMemoryProjectDraftStorage();
      final project = _project();
      await firstWorkspace.write(
        project.id,
        ProjectDraft.capture(project, 0, 1),
      );

      final replacementWorkspace = InMemoryProjectDraftStorage();
      expect(await replacementWorkspace.readAll(), isEmpty);
      await firstWorkspace.remove(project.id);
      expect(await firstWorkspace.readAll(), isEmpty);
    },
  );
}

SavedProject _project() => SavedProject(
  id: 'experiment',
  createdAt: DateTime.utc(2026, 10, 31),
  updatedAt: DateTime.utc(2026, 10, 31),
  formModel: ProjectFormModel()..setProjectTitle('Draft'),
);
