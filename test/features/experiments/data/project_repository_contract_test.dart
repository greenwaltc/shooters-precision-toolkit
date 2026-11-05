import 'package:bramwells_precision_test_kit/features/experiments/data/ephemeral_project_repository.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_project_repository.dart';
import '../../../support/project_repository_contract.dart';

void main() {
  projectRepositoryContract(
    'in-memory fake',
    () async => FakeProjectRepository(),
  );
  projectRepositoryContract('ephemeral adapter', () async {
    var nextId = 0;
    final repository = EphemeralProjectRepository(
      clock: Clock.fixed(DateTime.utc(2026, 11, 4)),
      newId: () => 'contract-${++nextId}',
    );
    addTearDown(repository.dispose);
    return repository;
  });
}
