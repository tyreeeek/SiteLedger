#!/usr/bin/env node

/**
 * Production server for SiteLedger Web
 * Runs Next.js with production-ready logging
 */

const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');

const dev = false;
const hostname = 'siteledger.ai';
const port = parseInt(process.env.PORT || '3001', 10);

const app = next({ dev, hostname, port });
const handle = app.getRequestHandler();

app.prepare().then(() => {
  createServer(async (req, res) => {
    try {
      const parsedUrl = parse(req.url, true);
      await handle(req, res, parsedUrl);
    } catch (err) {
      console.error('Error occurred handling', req.url, err);
      res.statusCode = 500;
      res.end('Internal server error');
    }
  })
    .once('error', (err) => {
      console.error(err);
      process.exit(1);
    })
    .listen(port, () => {
      console.log(`✅ SiteLedger Web Production Server`);
      console.log(`🌐 External: https://siteledger.ai`);
      console.log(`🔌 API: https://api.siteledger.ai`);
      console.log(`📊 Status: Ready and serving requests`);
    });
});
