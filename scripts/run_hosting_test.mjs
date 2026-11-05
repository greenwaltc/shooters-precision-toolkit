import { spawn } from 'node:child_process';
import { mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { reserveEmulatorPorts } from './emulator_ports.mjs';
import { root, verifyRelease } from './web_release.mjs';

const environment = process.argv[2];
await verifyRelease(environment);
const directory = await mkdtemp(path.join(tmpdir(), 'precision-hosting-'));
const project = `demo-precision-hosting-${process.pid.toString(36)}`;
const ports = await reserveEmulatorPorts(['hosting', 'hub', 'logging']);
try {
  const { hosting } = JSON.parse(await readFile(path.join(root, `firebase.${environment}.json`), 'utf8'));
  const config = path.join(directory, 'firebase.json');
  await symlink(path.join(root, hosting.public), path.join(directory, 'public'), 'dir');
  await writeFile(config, JSON.stringify({
    hosting: { ...hosting, site: project, public: 'public' },
    emulators: { ...ports.endpoints, ui: { enabled: false } },
  }));
  await ports.release();
  const emulator = spawn('npx', [
    '-y', 'firebase-tools@latest', 'emulators:exec', '--only', 'hosting', '--config',
    config, '--project', project, `node scripts/tests/hosting_smoke.mjs ${environment}`,
  ], { cwd: root, stdio: 'inherit' });
  process.exitCode = await new Promise((resolve, reject) => {
    emulator.once('error', reject);
    emulator.once('exit', (code) => resolve(code ?? 1));
  });
} finally {
  await ports.release();
  await rm(directory, { recursive: true, force: true });
}
