// A fresh headless Chrome load. Local mode serves gzip, approximating Hosting
// transfer; pass a deployed HTTPS URL as the second argument for CDN evidence.
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { gzipSync } from 'node:zlib';
import { root, settings, verifyRelease } from './web_release.mjs';

const [environment, deployedUrl] = process.argv.slice(2);
let browser, server, profile;
try {
  await verifyRelease(environment);
  const directory = path.join(root, `build/web-${environment}`);
  const contentTypes = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
    '.wasm': 'application/wasm', '.png': 'image/png', '.webp': 'image/webp', '.xml': 'application/xml', '.txt': 'text/plain',
    '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2', '.bin': 'application/octet-stream' };
  let localServerBytes = 0;
  const localTransfers = [];
  server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
      let file = path.resolve(directory, '.' + pathname);
      if (file !== directory && !file.startsWith(directory + path.sep)) throw new Error('Invalid path');
      if (pathname.endsWith('/')) file = path.join(file, 'index.html');
      let body;
      try { body = await readFile(file); } catch {
        file = path.join(directory, 'index.html');
        body = await readFile(file);
      }
      response.writeHead(200, { 'Content-Type': contentTypes[path.extname(file)] ?? 'application/octet-stream',
        'Content-Encoding': 'gzip', 'Cache-Control': 'no-store' });
      const compressed = gzipSync(body);
      // Count requests from worker targets too; page CDP events can omit those.
      localServerBytes += compressed.length;
      localTransfers.push({ path: pathname, bytes: compressed.length });
      response.end(compressed);
    } catch {
      response.writeHead(400);
      response.end();
    }
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const target = deployedUrl ?? `http://127.0.0.1:${server.address().port}/`;
  const origin = new URL(target).origin;
  if (deployedUrl && new URL(target).protocol !== 'https:') throw new Error('Use an HTTPS deployed URL.');
  profile = await mkdtemp(path.join(tmpdir(), 'precision-web-'));
  const executable = process.env.CHROME_EXECUTABLE ?? (process.platform === 'darwin'
    ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' : 'google-chrome');
  browser = spawn(executable, ['--headless=new', '--remote-debugging-pipe', '--no-first-run',
    '--no-default-browser-check', ...(process.env.CI ? ['--no-sandbox', '--disable-dev-shm-usage'] : []),
    `--user-data-dir=${profile}`, 'about:blank'],
  { stdio: ['ignore', 'ignore', 'ignore', 'pipe', 'pipe'] });
  let nextId = 0, buffer = '', lastActivity = Date.now();
  const pendingCommands = new Map(), requests = new Map(), inFlight = new Set();
  const failures = [], exceptions = [];
  let hostingBytes = 0, externalBytes = 0;
  function send(method, params = {}, sessionId) {
    const id = ++nextId;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => { pendingCommands.delete(id); reject(new Error(`Chrome timed out: ${method}`)); }, 15000);
      pendingCommands.set(id, { resolve, reject, timer });
      browser.stdio[3].write(JSON.stringify({ id, method, params, sessionId }) + '\0');
    });
  }
  browser.on('error', (error) => {
    for (const command of pendingCommands.values()) {
      clearTimeout(command.timer);
      command.reject(error);
    }
    pendingCommands.clear();
  });
  browser.stdio[4].on('data', (chunk) => {
    buffer += chunk.toString();
    let end;
    while ((end = buffer.indexOf('\0')) >= 0) {
      const message = JSON.parse(buffer.slice(0, end));
      buffer = buffer.slice(end + 1);
      if (message.id) {
        const command = pendingCommands.get(message.id);
        if (command) {
          clearTimeout(command.timer);
          pendingCommands.delete(message.id);
          if (message.error) command.reject(new Error(message.error.message));
          else command.resolve(message.result);
        }
        continue;
      }
      const params = message.params;
      if (message.method === 'Network.requestWillBeSent') {
        requests.set(params.requestId, params.request.url);
        inFlight.add(params.requestId);
        lastActivity = Date.now();
      } else if (message.method === 'Network.loadingFinished' || message.method === 'Network.loadingFailed') {
        const url = requests.get(params.requestId) ?? '';
        inFlight.delete(params.requestId);
        lastActivity = Date.now();
        if (message.method === 'Network.loadingFailed') failures.push(`${url}: ${params.errorText}`);
        else if (url.startsWith(origin + '/')) hostingBytes += params.encodedDataLength;
        else externalBytes += params.encodedDataLength;
      } else if (message.method === 'Runtime.exceptionThrown') {
        exceptions.push(params.exceptionDetails.exception?.description ?? params.exceptionDetails.text);
      }
    }
  });
  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
  await send('Network.enable', {}, sessionId);
  await send('Runtime.enable', {}, sessionId);
  await send('Page.enable', {}, sessionId);
  await send('Network.setCacheDisabled', { cacheDisabled: true }, sessionId);
  await send('Network.setBypassServiceWorker', { bypass: true }, sessionId);
  await send('Page.navigate', { url: target }, sessionId);
  const started = Date.now();
  let rendered = false;
  while (Date.now() - started < 60000) {
    await new Promise((resolve) => setTimeout(resolve, 250));
    if (Date.now() - started < 5000 || inFlight.size || Date.now() - lastActivity < 3000) continue;
    const result = await send('Runtime.evaluate', {
      expression: "!!document.querySelector('flutter-view')", returnByValue: true,
    }, sessionId);
    rendered = result.result.value === true;
    if (rendered) break;
  }
  if (!rendered || failures.length || exceptions.length) {
    throw new Error(`Cold load did not complete cleanly. ${[...failures, ...exceptions].join('\n')}`);
  }
  const budget = settings.trafficBudget;
  const pageObservedHostingBytes = hostingBytes;
  if (!deployedUrl) hostingBytes = Math.max(hostingBytes, localServerBytes);
  const projectedDailyBytes = (hostingBytes + budget.sessionReserveBytes) * budget.coldSessionsPerDay;
  const projectedMonthlyBytes = projectedDailyBytes * budget.planningDaysPerMonth;
  const report = { environment, target, measuredAt: new Date().toISOString(),
    mode: deployedUrl ? 'deployed CDN (page targets)' : 'local gzip approximation (including workers)',
    hostingBytes, pageObservedHostingBytes, localServerBytes: deployedUrl ? undefined : localServerBytes,
    externalBytes,
    requests: requests.size, ...budget, projectedDailyBytes, projectedMonthlyBytes,
    withinBudget: projectedDailyBytes <= budget.dailyHostingBytes && projectedMonthlyBytes <= budget.monthlyHostingBytes,
    localTransfers: deployedUrl ? undefined : localTransfers.sort((a, b) => b.bytes - a.bytes) };
  await writeFile(path.join(root, `build/web-transfer-${environment}.json`), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report, null, 2));
  if (!report.withinBudget) throw new Error('Cold-load traffic exceeds the planning budget. Optimize assets or reduce the session assumption.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally {
  if (browser?.pid && browser.exitCode === null && browser.signalCode === null) {
    const closed = new Promise((resolve) => browser.once('exit', resolve));
    browser.kill();
    await closed;
  }
  if (server?.listening) await new Promise((resolve) => server.close(resolve));
  if (profile) await rm(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 });
}
