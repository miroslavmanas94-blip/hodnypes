import { readFileSync, existsSync } from 'node:fs';
import vm from 'node:vm';

const requiredFiles = [
  'functions/_middleware.js',
  'functions/api/session.js',
  'functions/api/logout.js',
  'assets/site.js',
  'assets/platform.js',
  'assets/site.css',
  'manifest.webmanifest',
  'supabase/migrations/20261022180000_add_private_dog_media_storage.sql',
  'supabase/migrations/20261022190000_platform_core.sql',
  'supabase/migrations/20261022203000_realtime_events_reactions.sql',
  'supabase/migrations/20261022204000_event_capacity_waitlist.sql',
  'supabase/migrations/20261022202000_direct_messages.sql',
  'supabase/migrations/20261022201000_admin_review_access.sql',
  'supabase/migrations/20261022200000_admin_publishing_policies.sql',
];
const missing = requiredFiles.filter((file) => !existsSync(file));
if (missing.length) {
  console.error('Build check failed. Missing files:', missing.join(', '));
  process.exit(1);
}

const middleware = readFileSync('functions/_middleware.js', 'utf8')
  .replace('export async function onRequest', 'async function onRequest');
const browser = readFileSync('assets/site.js', 'utf8')
  .split('\n').slice(1).join('\n');
const platform = readFileSync('assets/platform.js', 'utf8').replace(/^import .*?;\s*/s, '');
const session = readFileSync('functions/api/session.js', 'utf8')
  .replace('export async function onRequestPost', 'async function onRequestPost');
const logout = readFileSync('functions/api/logout.js', 'utf8')
  .replace('export async function onRequestPost', 'async function onRequestPost');

for (const [name, source] of [
  ['Cloudflare Pages middleware', middleware],
  ['Browser JavaScript', browser],
  ['Member platform JavaScript', platform],
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

const middlewareSource = readFileSync('functions/_middleware.js', 'utf8');
const siteSource = readFileSync('assets/site.js', 'utf8');
const storageMigration = readFileSync('supabase/migrations/20261022180000_add_private_dog_media_storage.sql', 'utf8');
if (middlewareSource.includes('maps.google.com') || middlewareSource.includes('google.com/maps')) {
  console.error('✗ Privacy: map links must not be present on Hodný pes.');
  process.exitCode = 1;
}
if (!middlewareSource.includes('dog-photo-file') || !siteSource.includes("db.storage.from('dog-media').upload")) {
  console.error('✗ Storage: secure dog photo upload is not wired into the profile.');
  process.exitCode = 1;
}
if (!storageMigration.includes("public = false") || !storageMigration.includes('storage.objects') || !storageMigration.includes('auth.uid()')) {
  console.error('✗ Storage: private bucket and owner-only policies are required.');
  process.exitCode = 1;
}
if (!siteSource.includes('const systemTheme') || !siteSource.includes("prefers-color-scheme: dark")) {
  console.error('✗ Theme: system color-scheme preference is not supported.');
  process.exitCode = 1;
}
if (process.exitCode) process.exit(process.exitCode);
console.log('✓ Privacy, private media storage, and system theme checks passed');



const platformSource = readFileSync('assets/platform.js', 'utf8');
const coreMigration = readFileSync('supabase/migrations/20261022190000_platform_core.sql', 'utf8');
const messageMigration = readFileSync('supabase/migrations/20261022202000_direct_messages.sql', 'utf8');
const waitlistMigration = readFileSync('supabase/migrations/20261022204000_event_capacity_waitlist.sql', 'utf8');
if (platformSource.includes('navigator.geolocation') || platformSource.includes('getCurrentPosition') || platformSource.includes('watchPosition')) {
  console.error('✗ Privacy: location access is forbidden.');
  process.exitCode = 1;
}
for (const table of ['hp_posts','hp_comments','hp_reactions','hp_follows','hp_groups','hp_events','hp_missions','hp_training_entries','hp_courses','hp_articles','hp_notifications','hp_user_preferences','hp_reports']) {
  if (!coreMigration.includes('public.' + table)) {
    console.error('✗ Platform migration missing table:', table);
    process.exitCode = 1;
  }
}
if (!waitlistMigration.includes('hp_assign_event_waitlist') || !waitlistMigration.includes('hp_promote_event_waitlist')) {
  console.error('✗ Events: capacity and waitlist triggers are required.');
  process.exitCode = 1;
}
if (!messageMigration.includes('sender_id=auth.uid() or recipient_id=auth.uid()') || !messageMigration.includes('sender_id=auth.uid()')) {
  console.error('✗ Messaging: participant-only RLS is required.');
  process.exitCode = 1;
}
if (!readFileSync('index.html', 'utf8').includes('/assets/platform.js')) {
  console.error('✗ Platform UI is not connected to the homepage.');
  process.exitCode = 1;
}
if (process.exitCode) process.exit(process.exitCode);
console.log('✓ Platform modules, migration coverage, and no-location checks passed');
