import { readFile, readdir, mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export function coverageReport(lcov, sources, policy) {
  const records = new Map();
  for (const record of lcov.split('end_of_record')) {
    const file = record.match(/^SF:(.+)$/m)?.[1]?.replaceAll('\\', '/');
    if (!file) continue;
    records.set(file, [...record.matchAll(/^DA:(\d+),(\d+)/gm)].map((m) => Number(m[2])));
  }
  const files = [];
  for (const [file, source] of sources) {
    if (policy.generatedFiles.includes(file)) continue;
    const hits = records.get(file);
    // Never-loaded files are included at zero using a conservative denominator
    // of nonblank, non-comment lines. This cannot inflate the reported coverage.
    const conservativeLines = source.split('\n').filter((line) => {
      const text = line.trim();
      return text && !text.startsWith('//') && !text.startsWith('*') && !text.startsWith('/*');
    }).length;
    files.push({ file, found: hits?.length ?? conservativeLines,
      hit: hits?.filter((n) => n > 0).length ?? 0, loaded: Boolean(hits) });
  }
  const found = files.reduce((sum, file) => sum + file.found, 0);
  const hit = files.reduce((sum, file) => sum + file.hit, 0);
  return { schemaVersion: 1, found, hit, percent: found ? hit / found * 100 : 0,
    minimumPercent: policy.minimumPercent, files };
}

async function sourceFiles(directory) {
  const result = new Map();
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const file = path.posix.join(directory, entry.name);
    if (entry.isDirectory()) {
      for (const pair of await sourceFiles(file)) result.set(...pair);
    } else if (file.endsWith('.dart')) result.set(file, await readFile(file, 'utf8'));
  }
  return result;
}

if (process.argv[1] && import.meta.url === pathToFileURL(path.resolve(process.argv[1])).href) {
  const policy = JSON.parse(await readFile('config/coverage.json', 'utf8'));
  if (policy.schemaVersion !== 1 || policy.minimumPercent < 80 || policy.minimumPercent > 100) {
    throw new Error('Invalid coverage policy.');
  }
  const report = coverageReport(await readFile('coverage/lcov.info', 'utf8'), await sourceFiles('lib'), policy);
  await mkdir('build', { recursive: true });
  await writeFile('build/coverage-report.json', JSON.stringify(report, null, 2) + '\n');
  console.log(`Maintained Dart coverage: ${report.percent.toFixed(2)}% (${report.hit}/${report.found} lines); minimum ${policy.minimumPercent}%.`);
  if (report.percent < policy.minimumPercent) process.exitCode = 1;
}
