'use strict';

const { execFile } = require('child_process');
const crypto = require('crypto');
const http = require('http');
const { URL } = require('url');

const HOST = '127.0.0.1';
const PORT = Number(process.env.PORT || 3000);
const API_KEY = String(process.env.API_KEY || '');
const COMMAND_TIMEOUT_MS = Number(process.env.CMD_TIMEOUT_MS || 120000);
const MAX_BODY_BYTES = 32 * 1024;
const MAX_REQUESTS_PER_MINUTE = 60;
const rateBuckets = new Map();

if (!Number.isInteger(PORT) || PORT < 1024 || PORT > 65535) throw new Error('invalid PORT');
if (API_KEY.length < 32) throw new Error('API_KEY is missing or too short');

function sendJson(res, statusCode, body) {
  const payload = JSON.stringify(body);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff'
  });
  res.end(payload);
}

function cleanOutput(value) {
  return String(value || '')
    .replace(/\x1B\[[0-9;?]*[ -/]*[@-~]/g, '')
    .replace(/\[(?:\d{1,3}(?:;\d{1,3})*)?[HJKm]/g, '')
    .replace(/\r/g, '')
    .trim();
}

function truncate(value, limit) {
  const text = String(value || '');
  return text.length > limit ? `${text.slice(0, limit)}…` : text;
}

function isAuthorized(req) {
  const supplied = Buffer.from(String(req.headers['x-api-key'] || ''), 'utf8');
  const expected = Buffer.from(API_KEY, 'utf8');
  return supplied.length === expected.length && crypto.timingSafeEqual(supplied, expected);
}

function allowRequest(req) {
  const now = Date.now();
  const key = req.socket.remoteAddress || 'unknown';
  const bucket = rateBuckets.get(key) || { start: now, count: 0 };
  if (now - bucket.start >= 60000) {
    bucket.start = now;
    bucket.count = 0;
  }
  bucket.count += 1;
  rateBuckets.set(key, bucket);
  return bucket.count <= MAX_REQUESTS_PER_MINUTE;
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('request body too large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8');
        resolve(raw ? JSON.parse(raw) : {});
      } catch (_) {
        reject(new Error('invalid JSON body'));
      }
    });
    req.on('error', () => reject(new Error('request read failed')));
  });
}

function safeWord(value, field) {
  const text = String(value || '').trim();
  if (!/^[A-Za-z0-9_-]{3,32}$/.test(text)) throw new Error(`invalid ${field}`);
  return text;
}

function positiveInt(value, field, maximum) {
  const number = Number(value);
  if (!Number.isInteger(number) || number < 1 || number > maximum) throw new Error(`invalid ${field}`);
  return String(number);
}

function v2rayType(value) {
  const type = String(value || '').toLowerCase();
  if (!['vmess', 'vless', 'trojan'].includes(type)) throw new Error('invalid type');
  return type;
}

function commandFor(pathname, body) {
  switch (pathname) {
    case '/ssh':
      return { action: 'ssh-create', responseField: 'config_text', args: [safeWord(body.username, 'username'), safeWord(body.password, 'password'), positiveInt(body.iplimit, 'iplimit', 1000), positiveInt(body.duration, 'duration', 3650)] };
    case '/ssh/delete':
      return { action: 'ssh-delete', args: [safeWord(body.username, 'username')] };
    case '/ssh/renew':
      return { action: 'ssh-renew', args: [safeWord(body.username, 'username'), positiveInt(body.days, 'days', 3650)] };
    case '/v2ray': {
      const type = v2rayType(body.type);
      return { action: `v2ray-create-${type}`, responseField: 'config_text', args: [safeWord(body.username, 'username'), positiveInt(body.days, 'days', 3650), positiveInt(body.gb, 'gb', 1048576), positiveInt(body.ip, 'ip', 1000)] };
    }
    case '/v2ray/delete': {
      const type = v2rayType(body.type);
      return { action: `v2ray-delete-${type}`, args: [safeWord(body.username, 'username')] };
    }
    case '/v2ray/renew': {
      const type = v2rayType(body.type);
      return { action: `v2ray-renew-${type}`, args: [safeWord(body.username, 'username'), positiveInt(body.days, 'days', 3650), positiveInt(body.gb, 'gb', 1048576), positiveInt(body.ip, 'ip', 1000)] };
    }
    default:
      return null;
  }
}

function runAction(action, args) {
  return new Promise((resolve, reject) => {
    const started = Date.now();
    execFile('/usr/bin/sudo', ['-n', '/usr/local/lib/vpn-api/dispatch', action, ...args], {
      timeout: COMMAND_TIMEOUT_MS,
      maxBuffer: 4 * 1024 * 1024,
      env: { PATH: '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', TERM: 'dumb', NO_COLOR: '1', CLICOLOR: '0', FORCE_COLOR: '0' }
    }, (error, stdout, stderr) => {
      const output = cleanOutput(stdout);
      if (error) {
        reject(new Error(truncate(cleanOutput(stderr) || output || 'command failed', 2048)));
        return;
      }
      resolve({ output, durationMs: Date.now() - started });
    });
  });
}

const server = http.createServer(async (req, res) => {
  const started = Date.now();
  let pathname = '/';
  let statusCode = 500;
  try {
    pathname = new URL(req.url, `http://${req.headers.host || 'localhost'}`).pathname;
    if (!allowRequest(req)) {
      statusCode = 429;
      sendJson(res, statusCode, { ok: false, message: 'rate limit exceeded' });
      return;
    }
    if (!isAuthorized(req)) {
      statusCode = 401;
      sendJson(res, statusCode, { ok: false, message: 'unauthorized' });
      return;
    }
    if (req.method === 'GET' && pathname === '/health') {
      statusCode = 200;
      sendJson(res, statusCode, { ok: true, service: 'vpn-api', time: new Date().toISOString() });
      return;
    }
    if (req.method !== 'POST') {
      statusCode = 405;
      sendJson(res, statusCode, { ok: false, message: 'method not allowed' });
      return;
    }
    if (!String(req.headers['content-type'] || '').toLowerCase().startsWith('application/json')) {
      statusCode = 415;
      sendJson(res, statusCode, { ok: false, message: 'content-type must be application/json' });
      return;
    }
    const command = commandFor(pathname, await readJson(req));
    if (!command) {
      statusCode = 404;
      sendJson(res, statusCode, { ok: false, message: 'route not found' });
      return;
    }
    const result = await runAction(command.action, command.args);
    statusCode = 200;
    const response = { ok: true, duration_ms: result.durationMs };
    response[command.responseField || 'output'] = result.output;
    sendJson(res, statusCode, response);
  } catch (error) {
    const message = error && error.message ? error.message : 'request failed';
    statusCode = message.startsWith('invalid ') || message === 'request body too large' || message === 'invalid JSON body' ? 400 : 502;
    sendJson(res, statusCode, { ok: false, message: truncate(message, 2048) });
  } finally {
    console.log(`${new Date().toISOString()} ${req.socket.remoteAddress || '-'} ${req.method} ${pathname} ${statusCode} ${Date.now() - started}ms`);
  }
});

server.requestTimeout = COMMAND_TIMEOUT_MS + 10000;
server.headersTimeout = 20000;
server.keepAliveTimeout = 5000;
server.listen(PORT, HOST, () => console.log(`vpn-api listening on ${HOST}:${PORT}`));
