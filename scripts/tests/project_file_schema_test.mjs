import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { appendFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import test from 'node:test';
import { fileURLToPath } from 'node:url';

const script = fileURLToPath(new URL('../project_file_schema.mjs', import.meta.url));

test('schema updates bump once and the checks reject drift and reused versions', (t) => {
  const cwd = mkdtempSync(join(tmpdir(), 'project-file-schema-'));
  t.after(() => rmSync(cwd, { recursive: true, force: true }));
  const feature = 'lib/features/experiments';
  const contract = `${feature}/api/project_snapshot.dart`;
  const stamp = join(cwd, `${feature}/domain/project_file_version.dart`);
  for (const [file, content] of Object.entries({
    [contract]: 'Snapshot shape',
    [`${feature}/api/test_design.dart`]: 'Design shape',
    [`${feature}/domain/project_file_codec.dart`]: 'File contract',
    [`${feature}/domain/range_value_parser.dart`]: 'Measurement contract',
    [`${feature}/domain/sample_size_catalog.dart`]: 'Sample options',
    'lib/shared/foundation/behavior_policy.dart':
      'const maxProjectTitleLength = 200; const maxProjectFileBytes = 256 * 1024;',
  })) {
    mkdirSync(dirname(join(cwd, file)), { recursive: true });
    writeFileSync(join(cwd, file), content);
  }
  const run = (...args) => spawnSync(process.execPath, [script, ...args], {
    cwd,
    encoding: 'utf8',
  });
  const git = (...args) => {
    const result = spawnSync('git', args, { cwd, encoding: 'utf8' });
    assert.equal(result.status, 0, result.stderr);
  };
  assert.match(run('--update').stdout, /version 1\./);
  git('init', '--quiet');
  git('add', '.');
  git('-c', 'user.name=Schema test', '-c', 'user.email=schema@example.test',
    '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'Version one');
  assert.equal(run('--base', 'HEAD').status, 0);
  appendFileSync(join(cwd, contract), '\nNew field');
  assert.match(run().stderr, /contract changed/);
  assert.match(run('--update').stdout, /version 2\./);
  assert.match(run('--update').stdout, /version 2\./);
  assert.equal(run('--base', 'HEAD').status, 0);

  const stale = readFileSync(stamp, 'utf8').replace('Version = 2;', 'Version = 1;');
  writeFileSync(stamp, stale);
  assert.equal(run().status, 0);
  assert.notEqual(run('--base', 'HEAD').status, 0);
  assert.match(run('--update', '--base', 'HEAD').stdout, /version 2\./);
});
