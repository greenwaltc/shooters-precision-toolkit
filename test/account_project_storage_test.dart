import 'package:bramwells_precision_test_kit/model/project_store.dart';
import 'package:bramwells_precision_test_kit/storage/account_project_storage.dart';
import 'package:bramwells_precision_test_kit/storage/project_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'two UIDs reload their own projects without adopting legacy data',
    () async {
      const legacy = '{"projects":[],"legacyMarker":"preserve-me"}';
      SharedPreferences.setMockInitialValues({'anomr_projects_v1': legacy});
      ProjectStore storeFor(String uid, {String project = 'dev-project'}) =>
          ProjectStore(
            storage: AccountProjectStorage(projectId: project, uid: uid),
          );

      final alice = storeFor('alice');
      final bob = storeFor('bob');
      final aliceAgain = storeFor('alice');
      final bobAgain = storeFor('bob');
      final productionAlice = storeFor('alice', project: 'prod-project');
      for (final store in [alice, bob, aliceAgain, bobAgain, productionAlice]) {
        addTearDown(store.dispose);
      }

      await alice.load();
      final aliceProject = await alice.createProject();
      aliceProject.formModel.setProjectTitle('Alice private project');
      await alice.flush();
      await bob.load();
      expect(bob.projects, isEmpty);
      final bobProject = await bob.createProject();
      bobProject.formModel.setProjectTitle('Bob private project');
      await bob.flush();

      await aliceAgain.load();
      await bobAgain.load();
      expect(aliceAgain.projects.map((p) => p.displayName), [
        'Alice private project',
      ]);
      expect(bobAgain.projects.map((p) => p.displayName), [
        'Bob private project',
      ]);
      expect(aliceAgain.projects.single.id, aliceProject.id);
      expect(bobAgain.projects.single.id, bobProject.id);
      await productionAlice.load();
      expect(productionAlice.projects, isEmpty);
      expect(
        await SharedPreferencesProjectStorage().readProjectsJson(),
        legacy,
      );
    },
  );
}
