import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const udid = process.env.SIMULATOR_UDID;
const session = process.env.WDA_SESSION_ID;
assert.ok(udid && session, 'Set SIMULATOR_UDID and WDA_SESSION_ID for a running simulator/WDA');
const wda = (process.env.WDA_URL || 'http://127.0.0.1:8100').replace(/\/$/, '');
const dir = fileURLToPath(new URL('.', import.meta.url));
const output = mkdtempSync(join(tmpdir(), 'offscreen-pagination-'));
const bundle = 'dev.midscene.offscreenpagination';
const app = join(output, 'Probe.app');
const xcrun = (...args) => execFileSync('xcrun', args, { encoding: 'utf8' }).trim();
const sim = (...args) => xcrun('simctl', ...args);
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
async function request(endpoint, body) {
  const response = await fetch(`${wda}/session/${session}${endpoint}`, {
    method: body ? 'POST' : 'GET', headers: { 'Content-Type': 'application/json' },
    ...(body ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(30000),
  });
  const data = await response.json();
  assert.ok(response.ok && !data.value?.error, JSON.stringify(data.value?.error || response.status));
  return data.value;
}
mkdirSync(app);
copyFileSync(join(dir, 'Info.plist'), join(app, 'Info.plist'));
const sdk = xcrun('--sdk', 'iphonesimulator', '--show-sdk-path');
const arch = process.arch === 'arm64' ? 'arm64' : 'x86_64';
xcrun('--sdk', 'iphonesimulator', 'swiftc', '-sdk', sdk, '-target', `${arch}-apple-ios18.0-simulator`, join(dir, 'Probe.swift'), '-o', join(app, 'Probe'));
execFileSync('codesign', ['--force', '--sign', '-', app]);
sim('install', udid, app);
const settings = await request('/appium/settings');
assert.ok(settings.snapshotMaxDepth >= 20, 'Use normal snapshot depth; a shallow snapshot hides the reproduction');
console.log(`Artifacts: ${output}`);

for (const [method, fixed] of [['actions', false], ['actions', true], ['legacy', false], ['legacy', true], ['source', false], ['source', true], ['screenshot', false], ['swipe', true]]) {
  const name = `${method}-${fixed ? 'fixed' : 'baseline'}`;
  sim('launch', '--terminate-running-process', udid, bundle, ...(fixed ? ['--guard-visibility'] : []), ...(method === 'swipe' ? ['--near-top'] : []));
  const container = sim('get_app_container', udid, bundle, 'data');
  const eventsFile = join(container, 'Documents', 'events.json');
  await delay(1000);
  const before = JSON.parse(readFileSync(eventsFile));
  const ready = before.find(e => e.event === 'ready');
  assert.ok(ready, 'App must be ready before the request');
  assert.equal(before.filter(e => e.event === 'preload').length, 0);
  const [width, height] = ready.size.match(/[\d.]+/g).map(Number);
  const x = width - 117, y = height - 216;
  sim('io', udid, 'screenshot', join(output, `${name}-before.png`));
  if (method === 'source' || method === 'screenshot') await request(`/${method}`);
  else if (method === 'legacy') await request('/wda/touchAndHold', { x, y, duration: 3 });
  else await request('/actions', { actions: [{ type: 'pointer', id: 'finger1', parameters: { pointerType: 'touch' }, actions: [
    { type: 'pointerMove', duration: 0, x: method === 'swipe' ? 180 : x, y: method === 'swipe' ? 300 : y },
    { type: 'pointerDown', button: 0 },
    method === 'swipe' ? { type: 'pointerMove', duration: 500, x: 180, y: 700 } : { type: 'pause', duration: 3000 },
    { type: 'pointerUp', button: 0 },
  ] }] });
  await delay(500);
  const events = JSON.parse(readFileSync(eventsFile));
  const active = events.slice(before.length);
  writeFileSync(join(output, `${name}.json`), JSON.stringify(events, null, 2));
  sim('io', udid, 'screenshot', join(output, `${name}-after.png`));
  const preloads = active.filter(e => e.event === 'preload');
  const scrolls = active.filter(e => e.event === 'scroll');
  const touches = active.filter(e => e.event === 'touch');
  const shouldLoad = method === 'swipe' || (!fixed && method !== 'screenshot');
  assert.equal(preloads.length, shouldLoad ? 1 : 0, name);
  if (!shouldLoad) assert.equal(scrolls.length, 0, name);
  else assert.ok(scrolls.length > 0, name);
  if (method === 'source' || method === 'screenshot') assert.equal(touches.length, 0, name);
  else if (method !== 'swipe') {
    assert.deepEqual(touches.map(e => [e.phase, e.x, e.y]), [[0, x, y], [3, x, y]], name);
    if (fixed) assert.ok(active.some(e => e.event === 'longPress' && e.row === 118 && e.state === 1), name);
  } else {
    assert.equal(preloads[0].row, 10);
    assert.ok(preloads[0].time > touches[0].time);
    assert.ok(active.some(e => e.event === 'willDisplay' && e.row === 10 && e.intersectsViewport));
  }
  console.log(`PASS ${name}: ${preloads.length} history requests, ${scrolls.length} scroll callbacks, ${touches.length} touch events`);
}
console.log('All eight reduced-fixture cases passed. Full IM Demo/device acceptance is still required.');
