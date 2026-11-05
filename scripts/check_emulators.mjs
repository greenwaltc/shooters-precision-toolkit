// Fail early rather than opening an app that cannot reach its local services.
try {
  const response = await fetch('http://127.0.0.1:4400/emulators', {
    signal: AbortSignal.timeout(3000),
  });
  if (!response.ok) throw new Error(`Emulator Hub returned ${response.status}`);
  const services = await response.json();
  for (const [name, port] of [['auth', 9099], ['firestore', 8080]]) {
    if (services[name]?.port !== port) throw new Error(`${name} is not running on port ${port}`);
    const health = await fetch(`http://127.0.0.1:${port}/`, {
      signal: AbortSignal.timeout(3000),
    });
    // A 404 also establishes that the local HTTP service is listening.
    if (health.status >= 500) throw new Error(`${name} returned ${health.status}`);
  }
  console.log('Local Auth and Firestore emulators are ready.');
} catch (error) {
  console.error(`Emulators unavailable: ${error.message}. Start them with task emulators:start, or use task local.`);
  process.exitCode = 1;
}
