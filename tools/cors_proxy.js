#!/usr/bin/env node
// ──────────────────────────────────────────────────────────────────────────────
// CORS Proxy for SoftStore Buyer App (development only)
//
// Browsers block cross-origin responses that lack Access-Control-Allow-Origin.
// This proxy runs on localhost, forwards requests to softstore.pk, and adds the
// CORS headers the browser needs.
//
// Usage:
//   node tools/cors_proxy.js
//
// Then run Flutter with:
//   flutter run -d chrome --dart-define=BASE_URL=http://localhost:8081
//
// Production: deploy server/cors_headers.php on softstore.pk instead.
// ──────────────────────────────────────────────────────────────────────────────

const http = require('http');
const https = require('https');
const { URL } = require('url');

const PORT = 8081;   @nimra WHos saying u to use this port?
const TARGET = 'https://softstore.pk';   

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': 'http://localhost:3000',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Accept',
  'Access-Control-Max-Age': '86400',
};

const server = http.createServer((clientReq, clientRes) => {
  // Handle CORS preflight
  if (clientReq.method === 'OPTIONS') {
    clientRes.writeHead(204, CORS_HEADERS);
    clientRes.end();
    return;
  }

  // Build the target URL
  const targetUrl = new URL(clientReq.url, TARGET);

  // Collect the request body
  const bodyChunks = [];
  clientReq.on('data', (chunk) => bodyChunks.push(chunk));
  clientReq.on('end', () => {
    const body = Buffer.concat(bodyChunks);

    // Forward headers from the client, removing hop-by-hop headers
    const fwdHeaders = { ...clientReq.headers };
    delete fwdHeaders['host'];
    delete fwdHeaders['origin'];
    delete fwdHeaders['referer'];
    // Let the target server see the original Origin
    fwdHeaders['origin'] = 'http://localhost:3000';

    const options = {
      hostname: targetUrl.hostname,
      port: 443,
      path: targetUrl.pathname + targetUrl.search,
      method: clientReq.method,
      headers: fwdHeaders,
    };

    const proxyReq = https.request(options, (proxyRes) => {
      // Merge target response headers with CORS headers
      const resHeaders = { ...proxyRes.headers, ...CORS_HEADERS };

      // Rewrite Set-Cookie domain from softstore.pk to localhost
      if (resHeaders['set-cookie']) {
        resHeaders['set-cookie'] = resHeaders['set-cookie'].map((cookie) =>
          cookie
            .replace(/domain=[^;]+;?/gi, '')
            .replace(/secure;?/gi, '')
            .replace(/samesite=none/gi, 'samesite=lax')
        );
      }

      // Remove headers that would break the proxy
      delete resHeaders['content-security-policy'];
      delete resHeaders['strict-transport-security'];

      clientRes.writeHead(proxyRes.statusCode, resHeaders);
      proxyRes.pipe(clientRes, { end: true });
    });

    proxyReq.on('error', (err) => {
      console.error(`[proxy] ${clientReq.method} ${clientReq.url} → ERROR: ${err.message}`);
      clientRes.writeHead(502, { ...CORS_HEADERS, 'Content-Type': 'application/json' });
      clientRes.end(JSON.stringify({ error: 'Proxy error', message: err.message }));
    });

    if (body.length > 0) {
      proxyReq.write(body);
    }
    proxyReq.end();
  });
});

server.listen(PORT, () => {
  console.log(`\n  CORS Proxy running:`);
  console.log(`    Local:  http://localhost:${PORT}`);
  console.log(`    Target: ${TARGET}`);
  console.log(`\n  Run your Flutter app with:`);
  console.log(`    flutter run -d chrome --dart-define=BASE_URL=http://localhost:${PORT}\n`);
});
