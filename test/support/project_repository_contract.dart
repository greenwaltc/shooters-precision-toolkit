import 'package:bramwells_precision_test_kit/features/experiments/api/project_repository.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/saved_project.dart';
import 'package:bramwells_precision_test_kit/features/experiments/presentation/test_design/project_form_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared observable adapter contract. The creator owns isolated data cleanup.
void projectRepositoryContract(
  String adapter,
  Future<ProjectRepository> Function() create,
) {
  group('$adapter repository contract', () {
    test(
      'a bounded recent page and older cursor contain each saved project once',
      () async {
        final repository = await create();
        final ids = <String>{};
        final now = DateTime.utc(2026, 11, 4);
        for (var index = 0; index < ProjectRepository.pageSize + 1; index++) {
          final id = repository.newProjectId();
          ids.add(id);
          await repository.saveProject(
            SavedProject(
              id: id,
              createdAt: now,
              updatedAt: now,
              formModel: ProjectFormModel()..setProjectTitle('Page fixture'),
            ),
            expectedRevision: 0,
          );
        }
        final recent = await repository
            .watchProjects()
            .firstWhere(
              (page) =>
                  !page.isFromCache &&
                  page.length == ProjectRepository.pageSize,
            )
            .timeout(const Duration(seconds: 10));
        expect(recent, hasLength(ProjectRepository.pageSize));
        final older = await repository.fetchOlderProjects(after: recent.last);
        expect(older, hasLength(1));
        expect(
          [...recent, ...older].map((record) => record.project.id).toSet(),
          ids,
        );
        expect(await repository.fetchOlderProjects(after: older.last), isEmpty);
        for (final id in ids) {
          await repository.deleteProject(id, expectedRevision: 1);
        }
      },
    );
    test(
      'missing, create, snapshot, update and delete retain revision semantics',
      () async {
        final repository = await create();
        final id = repository.newProjectId();
        final now = DateTime.utc(2026, 11, 4);
        final project = SavedProject(
          id: id,
          createdAt: now,
          updatedAt: now,
          formModel: ProjectFormModel()
            ..setProjectTitle('Anonymous contract fixture'),
        );
        expect(await repository.watchProject(id).first, isNull);
        expect(await repository.saveProject(project, expectedRevision: 0), 1);
        final saved = (await repository
            .watchProject(id)
            .firstWhere(
              (record) =>
                  record?.revision == 1 &&
                  !record!.hasPendingWrites &&
                  !record.isFromCache,
            )
            .timeout(const Duration(seconds: 10)))!;
        project.formModel.setProjectTitle('Changed after write');
        expect(saved.project.displayName, 'Anonymous contract fixture');
        expect(await repository.saveProject(project, expectedRevision: 1), 2);
        await repository.deleteProject(id, expectedRevision: 2);
        expect(
          await repository
              .watchProject(id)
              .firstWhere((record) => record == null)
              .timeout(const Duration(seconds: 10)),
          isNull,
        );
      },
    );

    test(
      'stale writes and deletes cannot overwrite a newer acknowledged revision',
      () async {
        final repository = await create();
        final id = repository.newProjectId();
        final now = DateTime.utc(2026, 11, 4);
        final project = SavedProject(
          id: id,
          createdAt: now,
          updatedAt: now,
          formModel: ProjectFormModel()..setProjectTitle('Original'),
        );
        await repository.saveProject(project, expectedRevision: 0);
        project.formModel.setProjectTitle('Stale overwrite');
        await expectLater(
          repository.saveProject(project, expectedRevision: 0),
          throwsA(isA<ProjectConflict>()),
        );
        await expectLater(
          repository.deleteProject(id, expectedRevision: 0),
          throwsA(isA<ProjectConflict>()),
        );
        expect(
          (await repository
                  .watchProject(id)
                  .firstWhere(
                    (record) =>
                        record?.revision == 1 &&
                        !record!.hasPendingWrites &&
                        !record.isFromCache,
                  )
                  .timeout(const Duration(seconds: 10)))!
              .project
              .displayName,
          'Original',
        );
        await repository.deleteProject(id, expectedRevision: 1);
      },
    );
  });
}
