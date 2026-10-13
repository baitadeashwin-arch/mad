// scripts/seed-live-firestore.mjs
// Writes seed collections directly to your live Firebase project using Firestore REST API

import fs from 'fs';
import path from 'path';

const plistPath = path.resolve('tinder-clone', 'GoogleService-Info.plist');
const seedDataDir = path.resolve('scripts', 'seed-data');

if (!fs.existsSync(plistPath)) {
  console.error('❌ GoogleService-Info.plist not found.');
  process.exit(1);
}

const plistContent = fs.readFileSync(plistPath, 'utf8');
function getPlistValue(key) {
  const match = plistContent.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`));
  return match ? match[1] : null;
}

const projectId = process.env.FIREBASE_PROJECT_ID || getPlistValue('PROJECT_ID') || 'tindercloneswiftui-3d25c';
const apiKey = process.env.FIREBASE_API_KEY || getPlistValue('API_KEY');

console.log(`================================================================`);
console.log(`🔥 Pushing Seed Collections to Live Firestore: "${projectId}"`);
console.log(`================================================================\n`);

// Helper to format values into Firestore REST format
function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    return Number.isInteger(val) ? { integerValue: val.toString() } : { doubleValue: val };
  }
  if (Array.isArray(val)) {
    return { arrayValue: { values: val.map(toFirestoreValue) } };
  }
  if (typeof val === 'object') {
    const fields = {};
    for (const [k, v] of Object.entries(val)) {
      fields[k] = toFirestoreValue(v);
    }
    return { mapValue: { fields } };
  }
  return { stringValue: String(val) };
}

async function writeDoc(collectionPath, docId, data) {
  const fields = {};
  for (const [key, val] of Object.entries(data)) {
    if (key !== 'id') {
      fields[key] = toFirestoreValue(val);
    }
  }

  const queryParam = apiKey ? `?key=${apiKey}` : '';
  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collectionPath}/${docId}${queryParam}`;

  const response = await fetch(url, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields })
  });

  const resJson = await response.json();
  if (!response.ok) {
    throw new Error(`[${response.status}] ${resJson.error?.message || response.statusText}`);
  }
  return resJson;
}

async function run() {
  const collections = ['users', 'userLocations', 'parties', 'matches', 'partyInvitations'];
  let totalWritten = 0;

  for (const col of collections) {
    const filePath = path.join(seedDataDir, `${col}.json`);
    if (!fs.existsSync(filePath)) continue;

    const docs = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    console.log(`📁 Collection "${col}" (${docs.length} documents):`);

    for (const doc of docs) {
      const docId = doc.id;
      try {
        await writeDoc(col, docId, doc);
        console.log(`   ✓ Written: ${col}/${docId}`);
        totalWritten++;

        // If match has messages subcollection, seed them too
        if (doc.messages && Array.isArray(doc.messages)) {
          for (let i = 0; i < doc.messages.length; i++) {
            const msg = doc.messages[i];
            const msgId = `msg_${i + 1}`;
            await writeDoc(`${col}/${docId}/messages`, msgId, msg);
            console.log(`     ↳ Subcollection message: ${col}/${docId}/messages/${msgId}`);
            totalWritten++;
          }
        }
      } catch (err) {
        console.error(`   ✗ Error writing ${col}/${docId}:`, err.message);
      }
    }
    console.log('');
  }

  // Also write an events collection (mirroring parties with isEvent = true)
  const partiesPath = path.join(seedDataDir, 'parties.json');
  if (fs.existsSync(partiesPath)) {
    const parties = JSON.parse(fs.readFileSync(partiesPath, 'utf8'));
    const events = parties.filter(p => p.isEvent);
    if (events.length > 0) {
      console.log(`📁 Collection "events" (${events.length} documents):`);
      for (const ev of events) {
        try {
          await writeDoc('events', ev.id, ev);
          console.log(`   ✓ Written: events/${ev.id}`);
          totalWritten++;
        } catch (err) {
          console.error(`   ✗ Error writing events/${ev.id}:`, err.message);
        }
      }
      console.log('');
    }
  }

  console.log(`================================================================`);
  console.log(`🎉 Success! Total ${totalWritten} documents written to "${projectId}".`);
  console.log(`👉 Open your Firebase Console to see all collections immediately:`);
  console.log(`   https://console.firebase.google.com/project/${projectId}/firestore/databases/-default-/data`);
  console.log(`================================================================\n`);
}

run().catch(console.error);
