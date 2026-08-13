'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('path');
const request = require('supertest');
const { createApp } = require('../src/app');

// Fake apsClient — no test here ever touches the real network. Real APS
// behavior is exercised by ../Deploy-And-Test-DA.ps1, which the user already
// ran successfully against the real WorkItem before this demo was built.
function fakeApsClient(overrides = {}) {
  return {
    getToken: async () => 'fake-token',
    ensureBucket: async () => {},
    uploadToOSS: async () => 'objectId',
    getSignedUrl: async (token, bucket, key, access) => `https://example.invalid/${key}?access=${access}`,
    submitWorkItem: async () => 'wi-123',
    waitForWorkItem: async () => ({ status: 'success' }),
    downloadBuffer: async () => Buffer.from('FAKE DWG BYTES'),
    ...overrides,
  };
}

const config = {
  clientId: 'id',
  clientSecret: 'secret',
  owner: 'madcad',
  alias: 'dev',
  activityId: 'FlangeDaActivity',
  bucketKey: 'madcad-flangeda-web-demo',
  schemaPath: path.join(__dirname, '..', '..', 'params.schema.json'),
};

function validRunRequest(app) {
  return request(app)
    .post('/run')
    .field('PatternDiameter', '180')
    .field('NumberOfHoles', '6')
    .field('HoleDiameter', '18')
    .field('CenterX', '0')
    .field('CenterY', '0')
    .field('FlangeTangentAngleDegrees', '0')
    .field('RotationAngleDegrees', '0')
    .field('Offset', 'true')
    .attach('inputDwg', Buffer.from('DWG'), 'input.dwg');
}

test('GET /api/schema returns the HolePatternInput schema', async () => {
  const app = createApp({ apsClient: fakeApsClient(), config });
  const res = await request(app).get('/api/schema');
  assert.equal(res.status, 200);
  assert.ok(res.body.properties.PatternDiameter);
  assert.ok(res.body.properties.NumberOfHoles);
});

test('POST /run without a file returns 400', async () => {
  const app = createApp({ apsClient: fakeApsClient(), config });
  const res = await request(app).post('/run').field('PatternDiameter', '180');
  assert.equal(res.status, 400);
  assert.match(res.body.error, /inputDwg/);
});

test('POST /run with invalid params returns 400 without calling APS', async () => {
  let tokenCalled = false;
  const apsClient = fakeApsClient({
    getToken: async () => {
      tokenCalled = true;
      return 'fake-token';
    },
  });
  const app = createApp({ apsClient, config });
  const res = await request(app)
    .post('/run')
    .field('PatternDiameter', '0')
    .field('NumberOfHoles', '6')
    .field('HoleDiameter', '18')
    .field('CenterX', '0')
    .field('CenterY', '0')
    .attach('inputDwg', Buffer.from('DWG'), 'input.dwg');
  assert.equal(res.status, 400);
  assert.equal(tokenCalled, false);
});

test('POST /run with valid params streams back the result dwg bytes', async () => {
  const app = createApp({ apsClient: fakeApsClient(), config });
  const res = await validRunRequest(app).buffer(true);
  assert.equal(res.status, 200);
  assert.equal(res.headers['content-type'], 'application/octet-stream');
  assert.ok(Buffer.isBuffer(res.body));
  assert.equal(res.body.toString(), 'FAKE DWG BYTES');
});

test('POST /run surfaces a WorkItem failure as 502 with the report URL', async () => {
  const apsClient = fakeApsClient({
    waitForWorkItem: async () => ({ status: 'failedLimitDataSize', reportUrl: 'https://example.invalid/report' }),
  });
  const app = createApp({ apsClient, config });
  const res = await validRunRequest(app);
  assert.equal(res.status, 502);
  assert.equal(res.body.reportUrl, 'https://example.invalid/report');
});

test('POST /run uses the fully-qualified <owner>.<activityId>+<alias> form', async () => {
  let seenActivityId;
  const apsClient = fakeApsClient({
    submitWorkItem: async (token, qualifiedActivityId) => {
      seenActivityId = qualifiedActivityId;
      return 'wi-123';
    },
  });
  const app = createApp({ apsClient, config });
  await validRunRequest(app);
  assert.equal(seenActivityId, 'madcad.FlangeDaActivity+dev');
});
