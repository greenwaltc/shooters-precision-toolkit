import { createServer } from 'node:net';

export const emulatorHost = '127.0.0.1';

/** Allocate distinct loopback ports while preparing a disposable emulator. */
export async function reserveEmulatorPorts(names) {
  const reservations = names.map(() => createServer());
  const release = () => Promise.all(reservations.map((server) =>
    server.listening ? new Promise((resolve) => server.close(resolve)) : Promise.resolve()));
  try {
    const ports = await Promise.all(reservations.map(async (server) => {
      await new Promise((resolve, reject) => {
        server.once('error', reject);
        server.listen(0, emulatorHost, resolve);
      });
      return server.address().port;
    }));
    return {
      endpoints: Object.fromEntries(names.map((name, index) => [name, { host: emulatorHost, port: ports[index] }])),
      release,
    };
  } catch (error) {
    await release();
    throw error;
  }
}
