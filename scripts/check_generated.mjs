import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';

const directory = 'lib/shared/l10n/generated';
async function hashes() {
  const files = (await readdir(directory)).filter((name) => name.endsWith('.dart')).sort();
  return Object.fromEntries(await Promise.all(files.map(async (name) => [
    name, createHash('sha256').update(await readFile(path.join(directory, name))).digest('hex'),
  ])));
}
const before = await hashes();
const generate = spawnSync('flutter', ['gen-l10n'], { stdio: 'inherit' });
if (generate.error) throw generate.error;
if (generate.status !== 0) process.exit(generate.status ?? 1);
const after = await hashes();
const git = (args) => spawnSync('git', args, { encoding: 'utf8' });
const tracked = process.argv.includes('--tracked');
const diff = tracked && git(['diff', '--quiet', 'HEAD', '--', directory]).status !== 0;
const untracked = tracked && git(['ls-files', '--others', '--exclude-standard', '--', directory]).stdout.trim().length !== 0;
if (JSON.stringify(before) !== JSON.stringify(after) || diff || untracked) {
  console.error('Localization outputs are stale. Regenerate with flutter gen-l10n and commit the reviewed outputs.');
  process.exitCode = 1;
} else {
  console.log('Generated localizations match the reviewed ARB resources.');
}
