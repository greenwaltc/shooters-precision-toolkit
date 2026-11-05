import assert from 'node:assert/strict';
import test from 'node:test';
import { coverageReport } from '../check_coverage.mjs';

test('new unexecuted source lowers coverage instead of disappearing', () => {
  const policy = { minimumPercent: 80, generatedFiles: [] };
  const lcov = 'SF:lib/tested.dart\nDA:1,1\nDA:2,1\nend_of_record\n';
  const sources = new Map([['lib/tested.dart', 'a\nb\n']]);
  assert.equal(coverageReport(lcov, sources, policy).percent, 100);
  sources.set('lib/untested.dart', 'void untested() {\n  throw StateError("unexecuted");\n}\n');
  const report = coverageReport(lcov, sources, policy);
  assert.equal(report.percent, 40);
  assert.equal(report.files[1].loaded, false);
});

test('only explicitly reviewed generated files leave the denominator', () => {
  const sources = new Map([['lib/handwritten.dart', 'run();'], ['lib/generated.dart', 'generated();']]);
  const report = coverageReport('', sources, { minimumPercent: 80, generatedFiles: ['lib/generated.dart'] });
  assert.equal(report.found, 1);
  assert.equal(report.files[0].file, 'lib/handwritten.dart');
});
