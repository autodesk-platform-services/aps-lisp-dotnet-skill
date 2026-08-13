'use strict';

const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const { buildHolePatternInput, validateHolePatternInput } = require('./validate');

const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 50 * 1024 * 1024 } });

// Factory, not a module-level app — lets tests inject a fake apsClient and a
// throwaway config instead of hitting the real network. See test/server.test.js.
function createApp({ apsClient, config }) {
  const app = express();
  app.use(express.static(path.join(__dirname, '..', 'public')));

  app.get('/api/schema', (req, res) => {
    const schema = JSON.parse(fs.readFileSync(config.schemaPath, 'utf8'));
    res.json(schema);
  });

  app.post('/run', upload.single('inputDwg'), async (req, res) => {
    try {
      if (!req.file) {
        return res.status(400).json({ error: 'inputDwg file is required.' });
      }

      const input = buildHolePatternInput(req.body);
      const { errors, warnings } = validateHolePatternInput(input);
      if (errors.length > 0) {
        return res.status(400).json({ error: errors.join(' ') });
      }

      const token = await apsClient.getToken(config.clientId, config.clientSecret);
      await apsClient.ensureBucket(token, config.bucketKey);

      // Distinct OSS object keys per run — the "outputFile shares localName with
      // inputFile" rule from activity.json is about the filename INSIDE the DA
      // sandbox (both map to "input.dwg" there), not the OSS storage key, so
      // input/output can (and should, to avoid collisions across concurrent runs)
      // live at different OSS locations.
      const runId = crypto.randomUUID();
      const inputKey = `${runId}/input.dwg`;
      const paramsKey = `${runId}/params.json`;
      const outputKey = `${runId}/result.dwg`;

      await apsClient.uploadToOSS(token, config.bucketKey, inputKey, req.file.buffer);
      await apsClient.uploadToOSS(token, config.bucketKey, paramsKey, Buffer.from(JSON.stringify(input, null, 2)));

      const inputUrl = await apsClient.getSignedUrl(token, config.bucketKey, inputKey, 'read');
      const paramsUrl = await apsClient.getSignedUrl(token, config.bucketKey, paramsKey, 'read');
      const outputWriteUrl = await apsClient.getSignedUrl(token, config.bucketKey, outputKey, 'write');

      const qualifiedActivityId = `${config.owner}.${config.activityId}+${config.alias}`;
      const workItemId = await apsClient.submitWorkItem(token, qualifiedActivityId, {
        inputFile: { url: inputUrl },
        params: { url: paramsUrl },
        outputFile: { url: outputWriteUrl },
      });

      const result = await apsClient.waitForWorkItem(token, workItemId);
      if (result.status !== 'success') {
        return res.status(502).json({
          error: `WorkItem ${result.status}`,
          reportUrl: result.reportUrl,
          warnings,
        });
      }

      const outputReadUrl = await apsClient.getSignedUrl(token, config.bucketKey, outputKey, 'read');
      const resultBuffer = await apsClient.downloadBuffer(outputReadUrl);

      res.set('Content-Type', 'application/octet-stream');
      res.set('Content-Disposition', 'attachment; filename="flange-result.dwg"');
      if (warnings.length > 0) {
        res.set('X-Warnings', warnings.join('; '));
      }
      res.send(resultBuffer);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  return app;
}

module.exports = { createApp };
