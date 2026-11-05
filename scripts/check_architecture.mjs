import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
async function sources(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  return (await Promise.all(entries.map((entry) => {
    const name = path.join(directory, entry.name);
    return entry.isDirectory() ? sources(name) : name.endsWith('.dart') ? [name] : [];
  }))).flat();
}

export function architectureErrors(graph) {
  const errors = [];
  const pure = (file) => /\/features\/[^/]+\/(api|domain)\//.test(file) || file.includes('/shared/foundation/');
  const feature = (file) => file.match(/\/features\/([^/]+)\//)?.[1];
  const featureGraph = new Map();
  for (const [file, dependencies] of graph) {
    for (const uri of dependencies) {
      const dependency = uri.replace(/^package:bramwells_precision_test_kit\//, '/lib/');
      if (pure(file)) {
        if (dependency.startsWith('package:') && !dependency.startsWith('package:clock/')) errors.push(`${file}: impure package ${dependency}`);
        if (dependency.startsWith('dart:') && ['dart:ui', 'dart:html', 'dart:js_interop'].includes(dependency)) errors.push(`${file}: platform library ${dependency}`);
        if (!dependency.includes(':') && !pure(dependency)) errors.push(`${file}: pure code depends on ${dependency}`);
      }
      if (file.includes('/shared/') && (dependency.includes('/features/') || dependency.includes('/app/'))) errors.push(`${file}: shared code depends on ${dependency}`);
      if (feature(file) && dependency.startsWith('/lib/app/')) errors.push(`${file}: feature depends on app composition ${dependency}`);
      if (/\/features\/[^/]+\/presentation\//.test(file) &&
          /^package:(firebase_[^/]+|cloud_firestore|shared_preferences)\//.test(dependency)) {
        errors.push(`${file}: presentation imports a persistence SDK ${dependency}`);
      }
      if (/\/features\/[^/]+\/presentation\//.test(file) && /\/features\/[^/]+\/data\//.test(dependency)) errors.push(`${file}: presentation imports concrete data ${dependency}`);
      if (/\/features\/[^/]+\/data\//.test(file) && /\/features\/[^/]+\/presentation\//.test(dependency)) errors.push(`${file}: data imports presentation ${dependency}`);
      const from = feature(file);
      const to = feature(dependency);
      if (from && to && from !== to) {
        if (!dependency.includes(`/features/${to}/api/`)) errors.push(`${file}: cross-feature dependency bypasses API ${dependency}`);
        if (!featureGraph.has(from)) featureGraph.set(from, new Set());
        featureGraph.get(from).add(to);
      }
    }
  }
  const visit = (node, ancestors) => {
    if (ancestors.includes(node)) { errors.push(`Feature cycle: ${[...ancestors, node].join(' -> ')}`); return; }
    for (const child of featureGraph.get(node) ?? []) visit(child, [...ancestors, node]);
  };
  for (const node of featureGraph.keys()) visit(node, []);
  return errors;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const graph = new Map();
  for (const absolute of await sources(path.join(root, 'lib'))) {
    const file = path.relative(root, absolute).split(path.sep).join('/');
    const source = await readFile(absolute, 'utf8');
    const dependencies = [];
    for (const declaration of source.matchAll(/^(?:import|export)\s+[\s\S]*?;/gm)) {
      for (const [, uri] of declaration[0].matchAll(/'([^']+)'/g)) {
        dependencies.push(uri.includes(':') ? uri : path.posix.normalize(path.posix.join(path.posix.dirname(file), uri)));
      }
    }
    graph.set(`/${file}`, dependencies.map((value) => value.includes(':') ? value : `/${value}`));
  }
  const errors = architectureErrors(graph);
  if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
  else console.log(`Architecture boundaries passed (${graph.size} Dart libraries).`);
}
