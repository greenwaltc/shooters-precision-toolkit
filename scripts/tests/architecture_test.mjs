import assert from 'node:assert/strict';
import test from 'node:test';
import { architectureErrors } from '../check_architecture.mjs';

test('architecture gate rejects SDK leakage, concrete adapters and feature cycles', () => {
  const graph = new Map([
    ['/lib/features/a/api/model.dart', ['package:flutter/widgets.dart']],
    ['/lib/features/a/presentation/page.dart', [
      'package:bramwells_precision_test_kit/features/a/data/repository.dart',
      '/lib/features/b/api/model.dart',
      '/lib/app/config/app_config.dart',
      'package:cloud_firestore/cloud_firestore.dart',
    ]],
    ['/lib/features/b/presentation/page.dart', ['/lib/features/a/api/model.dart']],
    ['/lib/shared/ui/button.dart', ['/lib/features/a/presentation/page.dart']],
  ]);
  const errors = architectureErrors(graph);
  assert(errors.some((error) => error.includes('impure package')));
  assert(errors.some((error) => error.includes('concrete data')));
  assert(errors.some((error) => error.includes('shared code')));
  assert(errors.some((error) => error.includes('app composition')));
  assert(errors.some((error) => error.includes('persistence SDK')));
  assert(errors.some((error) => error.includes('Feature cycle')));
});
test('pure contracts, adapters and composition retain the allowed direction', () => {
  assert.deepEqual(architectureErrors(new Map([
    ['/lib/features/a/api/model.dart', ['/lib/shared/foundation/value.dart']],
    ['/lib/features/a/domain/rule.dart', ['/lib/features/a/api/model.dart']],
    ['/lib/features/a/data/repository.dart', ['/lib/features/a/api/model.dart', 'package:cloud_firestore/cloud_firestore.dart']],
    ['/lib/app/application.dart', ['/lib/features/a/data/repository.dart', '/lib/features/a/presentation/page.dart']],
  ])), []);
});
