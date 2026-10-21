import { readFileSync, existsSync } from 'node:fs';
import vm from 'node:vm';

const requiredFiles = [
  'functions/_middleware.js',
  'functions/api/session.js',
  'functions/api/logout.js',
  'assets/site.js',
  'assets/site.css',
  'manifest.webmanifest',
];
const missing = requiredFiles.filter((file) => !existsSync(file));
if (missing.length) {
  console.error('Build check failed. Missing files:', missing.join(', '));
  process.exit(1);
}

const middleware = readFileSync('functions/_middleware.js', 'utf8')
  .replace('export async function onRequest', 'async function onRequest');
const browser = readFileSync('assets/site.js', 'utf8')
  .replace(/^import .*?;\\s*/m, '');
const session = readFileSync('functions/api/session.js', 'utf8')
  .replace('export async function onRequestPost', 'async function onRequestPost');
const logout = readFileSync('functions/api/logout.js', 'utf8')
  .replace('export async function onRequestPost', 'async function onRequestPost');

for (const [name, source] of [
  ['Cloudflare Pages middleware', middleware],
  ['Browser JavaScript', browser],
  ['Session endpoint', session],
  ['Logout endpoint', logout],
]) {
  try {
    new vm.Script(source, { filename: name });
    console.log('✓ Syntax:', name);
  } catch (error) {
    console.error('✗ Syntax:', name, error.message);
    process.exitCode = 1;
  }
}

try {
  const manifest = JSON.parse(readFileSync('manifest.webmanifest', 'utf8'));
  if (manifest.lang !== 'cs' || !manifest.start_url || !manifest.icons?.length) {
    throw new Error('Manifest is missing required app metadata.');
  }
  console.log('✓ Valid web app manifest');
} catch (error) {
  console.error('✗ Manifest:', error.message);
  process.exitCode = 1;
}

const routes = [
  '/', '/ucet/', '/akademie/', '/profil/', '/postup/', '/mise/',
  '/lekce/', '/kviz/', '/dog-puller/', '/historie/', '/souteze/',
  '/pripominky/', '/certifikaty/', '/administrace/', '/komunita/',
  '/zpravy/', '/trener/', '/rezervace/', '/plemena/',
];
for (const route of routes) {
  if (!middleware.includes("'" + route + "':{")) {
    console.error('✗ Missing route:', route);
    process.exitCode = 1;
  }
}
if (process.exitCode) process.exit(process.exitCode);
console.log('✓ Required route smoke checks passed');
