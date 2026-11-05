import { spawn } from 'node:child_process';
import { copyFile, mkdtemp, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { reserveEmulatorPorts } from './emulator_ports.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
// A private project plus private ports prevents cleanup of an interactive app.
const project = `demo-precision-rules-${process.pid.toString(36)}`;
const directory = await mkdtemp(path.join(tmpdir(), 'precision-rules-'));
const ports = await reserveEmulatorPorts(['firestore', 'hub', 'logging', 'websocket']);
try {
  const { firestore, hub, logging, websocket } = ports.endpoints;
  const config = path.join(directory, 'firebase.json');
  await copyFile(path.join(root, 'firestore.rules'), path.join(directory, 'firestore.rules'));
  await writeFile(config, JSON.stringify({
    firestore: { rules: 'firestore.rules', edition: 'standard' },
    emulators: {
      firestore: { ...firestore, websocketPort: websocket.port, edition: 'standard' },
      hub,
      logging,
      ui: { enabled: false },
      singleProjectMode: true,
    },
  }));
  await ports.release();
  const child = spawn('sh', ['scripts/firebase_emulators.sh', 'emulators:exec',
    '--config', config, '--only', 'firestore', '--project', project,
    'npm --prefix "$PRECISION_RULES_TEST_DIRECTORY" test'], {
    cwd: root, stdio: 'inherit',
    env: { ...process.env, PRECISION_RULES_TEST_PROJECT: project, PRECISION_RULES_TEST_PORT: String(firestore.port), PRECISION_RULES_TEST_DIRECTORY: path.join(root, 'security-tests') },
  });
  process.exitCode = await new Promise((resolve, reject) => {
    child.once('error', reject);
    child.once('exit', (code) => resolve(code ?? 1));
  });
} finally {
  await ports.release();
  await rm(directory, { recursive: true, force: true });
}
