import 'package:bramwells_precision_test_kit/storage/account_project_storage.dart';
import 'package:bramwells_precision_test_kit/storage/project_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy account JSON remains isolated and available for later import',
    () async {
      const legacy = '{"projects":[],"legacyMarker":"preserve-me"}';
      SharedPreferences.setMockInitialValues({'anomr_projects_v1': legacy});
      AccountProjectStorage storageFor(
        String uid, {
        String project = 'dev-project',
      }) => AccountProjectStorage(projectId: project, uid: uid);
      final alice = storageFor('alice');
      final bob = storageFor('bob');
      const aliceData = '{"projects":[{"id":"alice-project"}]}';
      const bobData = '{"projects":[{"id":"bob-project"}]}';
      expect(await alice.readProjectsJson(), isNull);
      await alice.writeProjectsJson(aliceData);
      expect(await bob.readProjectsJson(), isNull);
      await bob.writeProjectsJson(bobData);
      expect(await storageFor('alice').readProjectsJson(), aliceData);
      expect(await storageFor('bob').readProjectsJson(), bobData);
      expect(
        await storageFor('alice', project: 'prod-project').readProjectsJson(),
        isNull,
      );
      expect(
        await SharedPreferencesProjectStorage().readProjectsJson(),
        legacy,
      );
    },
  );
}
