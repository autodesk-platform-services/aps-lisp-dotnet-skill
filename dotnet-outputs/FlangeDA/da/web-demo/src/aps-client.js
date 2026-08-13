'use strict';

// Real APS Design Automation + OSS REST calls — mirrors ../APS-Common.ps1's
// endpoints/scopes/qualification exactly, translated to Node's built-in fetch.
// Every function here is injected into app.js via createApp({ apsClient, ... })
// so tests can swap in a fake client and never touch the network.

const DA_BASE = 'https://developer.api.autodesk.com/da/us-east/v3';
const OSS_BASE = 'https://developer.api.autodesk.com/oss/v2';
const AUTH_URL = 'https://developer.api.autodesk.com/authentication/v2/token';
const SCOPE = 'code:all data:read data:write bucket:create bucket:read bucket:update';

function authHeader(token) {
  return { Authorization: `Bearer ${token}` };
}

async function fetchJson(url, opts) {
  const res = await fetch(url, opts);
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`${opts?.method || 'GET'} ${url} -> ${res.status}: ${body}`);
  }
  return res.json();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function getToken(clientId, clientSecret) {
  const basic = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
  const res = await fetch(AUTH_URL, {
    method: 'POST',
    headers: { Authorization: `Basic ${basic}`, 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=client_credentials&scope=${encodeURIComponent(SCOPE)}`,
  });
  if (!res.ok) {
    throw new Error(`APS auth failed: ${res.status} ${await res.text()}`);
  }
  const json = await res.json();
  return json.access_token;
}

async function ensureBucket(token, bucketKey) {
  const details = await fetch(`${OSS_BASE}/buckets/${bucketKey}/details`, { headers: authHeader(token) });
  if (details.ok) return;
  // "transient" (24h auto-expiry) rather than APS-Common.ps1's "persistent" — this
  // bucket only holds ephemeral demo uploads/results, not deployed bundle artifacts.
  const res = await fetch(`${OSS_BASE}/buckets`, {
    method: 'POST',
    headers: { ...authHeader(token), 'Content-Type': 'application/json' },
    body: JSON.stringify({ bucketKey, policyKey: 'transient' }),
  });
  if (!res.ok && res.status !== 409) {
    throw new Error(`Bucket create failed: ${res.status} ${await res.text()}`);
  }
}

async function uploadToOSS(token, bucketKey, objectKey, buffer) {
  const encodedKey = encodeURIComponent(objectKey);
  const step1 = await fetchJson(
    `${OSS_BASE}/buckets/${bucketKey}/objects/${encodedKey}/signeds3upload?minutesExpiration=60&parts=1`,
    { headers: authHeader(token) }
  );
  const putRes = await fetch(step1.urls[0], { method: 'PUT', body: buffer });
  if (!putRes.ok) {
    throw new Error(`S3 PUT failed: ${putRes.status}`);
  }
  const completed = await fetchJson(
    `${OSS_BASE}/buckets/${bucketKey}/objects/${encodedKey}/signeds3upload`,
    {
      method: 'POST',
      headers: { ...authHeader(token), 'Content-Type': 'application/json' },
      body: JSON.stringify({ uploadKey: step1.uploadKey }),
    }
  );
  return completed.objectId;
}

async function getSignedUrl(token, bucketKey, objectKey, access) {
  const encodedKey = encodeURIComponent(objectKey);
  const r = await fetchJson(
    `${OSS_BASE}/buckets/${bucketKey}/objects/${encodedKey}/signed?access=${access}&minutesExpiration=60`,
    {
      method: 'POST',
      headers: { ...authHeader(token), 'Content-Type': 'application/json' },
      body: '{}',
    }
  );
  return r.signedUrl;
}

// qualifiedActivityId must already be "<owner>.<activityId>+<alias>" — see the
// lisp-to-dotnet skill's Design Automation Guardrail on fully-qualifying every DA
// reference; this function does not qualify it for you.
async function submitWorkItem(token, qualifiedActivityId, args) {
  const r = await fetchJson(`${DA_BASE}/workitems`, {
    method: 'POST',
    headers: { ...authHeader(token), 'Content-Type': 'application/json' },
    body: JSON.stringify({ activityId: qualifiedActivityId, arguments: args }),
  });
  return r.id;
}

async function waitForWorkItem(token, workItemId, { timeoutMs = 300000, pollMs = 5000 } = {}) {
  const deadline = Date.now() + timeoutMs;
  let status;
  do {
    await sleep(pollMs);
    status = await fetchJson(`${DA_BASE}/workitems/${workItemId}`, { headers: authHeader(token) });
  } while (['pending', 'inprogress'].includes(status.status) && Date.now() < deadline);
  return status;
}

async function downloadBuffer(url) {
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Download failed: ${res.status}`);
  }
  return Buffer.from(await res.arrayBuffer());
}

module.exports = {
  getToken,
  ensureBucket,
  uploadToOSS,
  getSignedUrl,
  submitWorkItem,
  waitForWorkItem,
  downloadBuffer,
};
