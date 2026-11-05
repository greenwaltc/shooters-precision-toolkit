import { execFileSync } from 'node:child_process';
import { lstat, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
// High-confidence server credentials only. Firebase client IDs/API keys are
// intentionally public configuration; never echo a matched credential.
const patterns = {
  privateKey: new RegExp(`-----BEGIN (?:RSA |EC |OPENSSH |DSA )?${'PRIVATE KEY'}-----`),
  githubCredential: /\b(?:gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{50,})\b/,
  oauthBearer: /\bya29\.[A-Za-z0-9_-]{30,}\b/,
  awsAccessId: /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/,
};
export function secretMatches(source) {
  return Object.entries(patterns).flatMap(([kind, regex]) => {
    const match = regex.exec(source);
    return match ? [{ kind, line: source.slice(0, match.index).split('\n').length }] : [];
  });
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const paths = execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'],
    { cwd: root, encoding: 'utf8' }).split('\0').filter(Boolean);
  const problems = [];
  for (const name of new Set(paths)) {
    if (!/\.(dart|mjs|js|ts|md|json|ya?ml|tf|sh|pem|txt|plist|xml|gradle|kts|lock)$/i.test(name)) continue;
    const absolute = path.join(root, name);
    const stat = await lstat(absolute).catch((error) => {
      if (error.code === 'ENOENT') return null; // A source move in the worktree.
      throw error;
    });
    if (!stat?.isFile()) continue;
    const source = await readFile(absolute, 'utf8');
    for (const finding of secretMatches(source)) problems.push(`${JSON.stringify(name)}:${finding.line}: possible ${finding.kind}`);
    if (name.startsWith('lib/') && name !== 'lib/app/config/app_config.dart' && /\bfromEnvironment\s*\(/.test(source)) {
      problems.push(`${name}: compilation declarations belong at the app configuration boundary`);
    }
    if (!name.endsWith('.md') || (name !== 'README.md' && !name.startsWith('docs/'))) continue;
    const prose = source.replace(/```[\s\S]*?```/g, '');
    for (const [, target] of prose.matchAll(/\[[^\]\n]+\]\(<?([^>\s)]+)>?(?:\s+"[^"]+")?\)/g)) {
      const location = target.split('#', 1)[0];
      if (!location || /^(?:[a-z]+:|\/)/i.test(location)) continue;
      const linked = path.resolve(path.dirname(absolute), decodeURIComponent(location));
      if (!await lstat(linked).catch(() => null)) problems.push(`${name}: broken relative link ${target}`);
    }
  }
  if (problems.length) { console.error(problems.join('\n')); process.exitCode = 1; }
  else console.log('Repository checks passed: relative documentation links, configuration boundary and high-confidence secret patterns.');
}
