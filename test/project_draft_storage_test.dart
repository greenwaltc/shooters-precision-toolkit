import 'package:bramwells_precision_test_kit/model/project_form_model.dart';
import 'package:bramwells_precision_test_kit/model/saved_project.dart';
import 'package:bramwells_precision_test_kit/storage/project_draft_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'anomr_projects_v1': 'legacy workspace',
    }),
  );

  test(
    'drafts freeze mutable form/matrix values with their revision and counter',
    () {
      final project = _project();
      project.matrixState['range_0'] = '1.5';
      final draft = ProjectDraft.capture(project, 4, 9);
      project.formModel.setProjectTitle('Changed later');
      project.matrixState['range_0'] = '2.5';
      final restored = ProjectDraft.decode(draft.encode());
      expect(restored.project.displayName, 'Draft');
      expect(restored.project.matrixState['range_0'], '1.5');
      expect(restored.expectedRevision, 4);
      expect(restored.editCounter, 9);
    },
  );

  test(
    'durable drafts are isolated by environment, account and project',
    () async {
      final alice = SharedPreferencesProjectDraftStorage(
        projectId: 'dev',
        uid: 'alice',
      );
      final bob = SharedPreferencesProjectDraftStorage(
        projectId: 'dev',
        uid: 'bob',
      );
      final prodAlice = SharedPreferencesProjectDraftStorage(
        projectId: 'prod',
        uid: 'alice',
      );
      final project = _project();
      await alice.write(project.id, ProjectDraft.capture(project, 1, 2));
      final another = _project(id: 'another');
      await alice.write(another.id, ProjectDraft.capture(another, 0, 1));
      final reopened = SharedPreferencesProjectDraftStorage(
        projectId: 'dev',
        uid: 'alice',
      );
      expect(
        (await reopened.readAll()).keys,
        unorderedEquals(['experiment', 'another']),
      );
      expect(await bob.readAll(), isEmpty);
      expect(await prodAlice.readAll(), isEmpty);
      await reopened.remove(project.id);
      expect((await alice.readAll()).keys, ['another']);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('anomr_projects_v1'), 'legacy workspace');
    },
  );

  test(
    'unsupported drafts fail visibly instead of silently discarding data',
    () async {
      expect(
        () => ProjectDraft.decode('{"schemaVersion":99}'),
        throwsFormatException,
      );
      final preferences = await SharedPreferences.getInstance();
      const key = 'project_drafts_v1/dev/alice/broken';
      await preferences.setString(key, 'not JSON');
      final storage = SharedPreferencesProjectDraftStorage(
        projectId: 'dev',
        uid: 'alice',
      );
      await expectLater(storage.readAll(), throwsFormatException);
      expect(preferences.getString(key), 'not JSON');
    },
  );
}

SavedProject _project({String id = 'experiment'}) => SavedProject(
  id: id,
  createdAt: DateTime.utc(2026, 10, 31),
  updatedAt: DateTime.utc(2026, 10, 31),
  formModel: ProjectFormModel()..setProjectTitle('Draft'),
);
