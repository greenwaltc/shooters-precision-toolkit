import { verifyRelease } from './web_release.mjs';

try {
  const config = await verifyRelease(process.argv[2]);
  console.log(`Verified ${config.environment} bundle → ${config.projectId}.`);
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
