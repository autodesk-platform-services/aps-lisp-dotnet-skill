'use strict';

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });
// Fallback to the project-root .env (D:\Temp\flange\.env) the user already has —
// dotenv.config() never overwrites a var that's already set, so da/.env (if it
// exists) always wins.
require('dotenv').config({ path: path.join(__dirname, '..', '..', '..', '..', '.env') });

const { createApp } = require('./app');
const apsClient = require('./aps-client');

const owner = process.env.APS_OWNER;
const config = {
  clientId: process.env.APS_CLIENT_ID,
  clientSecret: process.env.APS_CLIENT_SECRET,
  owner,
  alias: process.env.APS_ALIAS || 'dev',
  activityId: 'FlangeDaActivity',
  bucketKey: `${(owner || 'flangeda').toLowerCase()}-flangeda-web-demo`,
  schemaPath: path.join(__dirname, '..', '..', 'params.schema.json'),
};

if (!config.clientId || !config.clientSecret) {
  console.error(
    'APS_CLIENT_ID / APS_CLIENT_SECRET not set. Copy da/.env.example to da/web-demo/.env, ' +
      'or reuse the existing D:\\Temp\\flange\\.env (auto-loaded as a fallback).'
  );
  process.exit(1);
}
if (!config.owner) {
  // Deliberately NOT re-implementing APS-Common.ps1's Resolve-DANickname GET/PATCH
  // dance here — it's a documented flaky check (see project memory on the
  // Deploy-And-Test-DA.ps1 nickname bug). Require APS_OWNER explicitly instead.
  console.error('APS_OWNER not set. Set it explicitly in .env, e.g. APS_OWNER=madcad');
  process.exit(1);
}

const app = createApp({ apsClient, config });
const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`FlangeDA web demo listening on http://localhost:${port}`);
  console.log('LOCAL, UNAUTHENTICATED DEMO ONLY — no login, no rate limiting, no hardening.');
});
