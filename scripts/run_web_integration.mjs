import { spawn, execFileSync } from 'node:child_process';
import { createServer } from 'node:net';
import { mkdir, open } from 'node:fs/promises';

// The caller supplies the vendor ChromeDriver binary (see docs/verification/testing_evidence.md).
const driver = process.env.CHROMEDRIVER ?? 'chromedriver';
const size = process.env.BROWSER_DIMENSION ?? '1600x1024';
if (!/^\d{3,4}x\d{3,4}$/.test(size)) throw new Error('Use a browser size like 390x844.');
const port = await new Promise((resolve, reject) => {
  const server = createServer();
  server.on('error', reject);
  server.listen(0, '127.0.0.1', () => {
    const value = server.address().port;
    server.close(() => resolve(value));
  });
});
execFileSync(driver, ['--version'], { stdio: 'inherit' });
await mkdir('build/test-results', { recursive: true });
const log = await open(`build/test-results/chromedriver-${size}.log`, 'w');
const service = spawn(driver, [`--port=${port}`], { stdio: ['ignore', log.fd, log.fd] });
let processError;
service.on('error', (error) => { processError = error; });
try {
  const deadline = Date.now() + 15000;
  while (true) {
    if (processError) throw processError;
    if (service.exitCode !== null) throw new Error('ChromeDriver exited before becoming ready.');
    try {
      if ((await fetch(`http://127.0.0.1:${port}/status`, { signal: AbortSignal.timeout(500) })).ok) break;
    } catch { /* External-service readiness polling, not a unit-test sleep. */ }
    if (Date.now() >= deadline) throw new Error('ChromeDriver readiness timeout.');
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  const flutter = spawn('flutter', ['drive', '--driver=test_driver/integration_test.dart',
    '--target=integration_test/project_journey_test.dart', '-d', 'web-server',
    `--driver-port=${port}`, '--headless', `--browser-dimension=${size}`], { stdio: 'inherit' });
  const status = await new Promise((resolve, reject) => {
    flutter.on('error', reject);
    flutter.on('exit', (code) => resolve(code ?? 1));
  });
  process.exitCode = status;
} finally {
  service.kill('SIGTERM');
  await log.close();
}
