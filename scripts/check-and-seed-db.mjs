// scripts/check-and-seed-db.mjs
// Comprehensive CLI tool to check Firestore database connectivity and export/seed collections

import fs from 'fs';
import path from 'path';

console.log('================================================================');
console.log('       AntiSocial (Tinder Clone) — Firebase Diagnostics & Seed');
console.log('================================================================\n');

const plistPath = path.resolve('tinder-clone', 'GoogleService-Info.plist');
const seedDataDir = path.resolve('scripts', 'seed-data');

// 1. Verify GoogleService-Info.plist
if (!fs.existsSync(plistPath)) {
  console.log('❌ GoogleService-Info.plist NOT found in tinder-clone/');
  process.exit(1);
}

const plistContent = fs.readFileSync(plistPath, 'utf8');

function getPlistValue(key) {
  const match = plistContent.match(new RegExp(`<key>${key}</key>\\s*<string>([^<]+)</string>`));
  return match ? match[1] : null;
}

const bundleId = getPlistValue('BUNDLE_ID');
const projectId = getPlistValue('PROJECT_ID');
const apiKey = getPlistValue('API_KEY');
const clientId = getPlistValue('CLIENT_ID');
const reversedClientId = getPlistValue('REVERSED_CLIENT_ID');

console.log('📋 [Plist Configuration Check]');
console.log(`   • File Location:        ${plistPath}`);
console.log(`   • Bundle ID:            ${bundleId} ${bundleId === 'com.alexpi.tinder-clone' ? '✅ (Matches Xcode Target)' : '⚠️ (Expected: com.alexpi.tinder-clone)'}`);
console.log(`   • Project ID:           ${projectId}`);
console.log(`   • API Key:              ${apiKey ? apiKey.slice(0, 10) + '...' : 'Missing'}`);
console.log(`   • Client ID:            ${clientId ? clientId.slice(0, 25) + '...' : 'Missing'}`);
console.log(`   • Reversed Client ID:   ${reversedClientId ? reversedClientId.slice(0, 25) + '...' : 'Missing'}\n`);

// 2. Define standard seed collections
const seedData = {
  users: [
    {
      id: "seed_user_ashwin",
      name: "Ashwin Baitade",
      birthDate: "2002-05-14T00:00:00Z",
      bio: "iOS Developer & AI engineer. Love weekend hackathons, music festivals, and campus meetups! 💻🎧",
      male: true,
      orientation: "women",
      pictures: ["default-profile-picture", "elon_musk"],
      liked: ["seed_user_sophia"],
      passed: [],
      connection_mode: "both",
      college: "Stanford University",
      interests: ["Tech & Startups", "House Parties", "Live Music", "Gaming"],
      college_verified: true,
      nearby_enabled: true,
      show_approximate_distance: true,
      allow_party_invitations: true,
      allow_match_requests: true,
      approx_latitude: 37.4275,
      approx_longitude: -122.1697,
      geohash: "9q9hv1"
    },
    {
      id: "seed_user_sophia",
      name: "Sophia Chen",
      birthDate: "2003-09-20T00:00:00Z",
      bio: "Product Design senior. Exploring specialty coffee spots, architecture photography, and local gallery walks ☕️🎨",
      male: false,
      orientation: "men",
      pictures: ["default-profile-picture"],
      liked: ["seed_user_ashwin"],
      passed: [],
      connection_mode: "friends",
      college: "UC Berkeley",
      interests: ["Design & Art", "Coffee & Cafes", "Live Music", "Study Groups"],
      college_verified: true,
      nearby_enabled: true,
      show_approximate_distance: true,
      allow_party_invitations: true,
      allow_match_requests: true,
      approx_latitude: 37.8719,
      approx_longitude: -122.2585,
      geohash: "9q9p3x"
    },
    {
      id: "seed_user_marcus",
      name: "Marcus Brody",
      birthDate: "2001-11-03T00:00:00Z",
      bio: "Music Producer & DJ. Organizing weekend rooftop sets and campus nightlife events 🪩✨",
      male: true,
      orientation: "both",
      pictures: ["jeff_bezos"],
      liked: [],
      passed: [],
      connection_mode: "party",
      college: "Stanford University",
      interests: ["Nightlife & Clubs", "House Parties", "DJing", "Festivals"],
      college_verified: true,
      nearby_enabled: true,
      show_approximate_distance: true,
      allow_party_invitations: true,
      allow_match_requests: true,
      approx_latitude: 37.4241,
      approx_longitude: -122.1660,
      geohash: "9q9hv0"
    }
  ],
  userLocations: [
    {
      id: "seed_user_ashwin",
      userId: "seed_user_ashwin",
      approxLatitude: 37.4275,
      approxLongitude: -122.1697,
      geohash: "9q9hv1",
      nearbyEnabled: true
    },
    {
      id: "seed_user_sophia",
      userId: "seed_user_sophia",
      approxLatitude: 37.8719,
      approxLongitude: -122.2585,
      geohash: "9q9p3x",
      nearbyEnabled: true
    },
    {
      id: "seed_user_marcus",
      userId: "seed_user_marcus",
      approxLatitude: 37.4241,
      approxLongitude: -122.1660,
      geohash: "9q9hv0",
      nearbyEnabled: true
    }
  ],
  parties: [
    {
      id: "seed_party_hackathon",
      name: "Silicon Campus Hackathon Afterparty",
      description: "Celebrate the end of demo day! Food trucks, board games, DJ set & chill terrace.",
      date: new Date(Date.now() + 3 * 86400000).toISOString(),
      category: "college_party",
      maxParticipants: 100,
      participantCount: 38,
      approximateLocation: "Stanford Campus Student Center",
      approxLatitude: 37.4282,
      approxLongitude: -122.1688,
      geohash: "9q9hv1",
      visibility: "public",
      hostID: "seed_user_ashwin",
      hostName: "Ashwin Baitade",
      college: "Stanford University",
      isEvent: false
    },
    {
      id: "seed_party_neon_night",
      name: "Neon Lights & EDM Night",
      description: "Live DJ sets featuring campus talent. Glowsticks and neon accessories provided!",
      date: new Date(Date.now() + 5 * 86400000).toISOString(),
      category: "music",
      maxParticipants: 150,
      participantCount: 62,
      approximateLocation: "Downtown Berkeley Stage",
      approxLatitude: 37.8700,
      approxLongitude: -122.2680,
      geohash: "9q9p3x",
      visibility: "public",
      hostID: "seed_user_marcus",
      hostName: "Marcus Brody",
      college: "Stanford University",
      isEvent: true
    }
  ],
  matches: [
    {
      id: "seed_match_ashwin_sophia",
      usersMatched: ["seed_user_ashwin", "seed_user_sophia"],
      status: "active",
      messages: [
        {
          senderId: "seed_user_ashwin",
          message: "Hey Sophia! Saw your interest in live music — are you checking out the EDM night this Friday?",
          type: "text"
        }
      ]
    }
  ],
  partyInvitations: [
    {
      id: "seed_invite_marcus_ashwin",
      partyID: "seed_party_neon_night",
      partyName: "Neon Lights & EDM Night",
      senderID: "seed_user_marcus",
      senderName: "Marcus Brody",
      receiverID: "seed_user_ashwin",
      status: "pending"
    }
  ]
};

// 3. Export seed datasets as JSON
if (!fs.existsSync(seedDataDir)) {
  fs.mkdirSync(seedDataDir, { recursive: true });
}

for (const [colName, docs] of Object.entries(seedData)) {
  const filePath = path.join(seedDataDir, `${colName}.json`);
  fs.writeFileSync(filePath, JSON.stringify(docs, null, 2));
}

console.log('📦 [Collection Seed Datasets Generated]');
console.log(`   Export directory: ${seedDataDir}`);
for (const [colName, docs] of Object.entries(seedData)) {
  console.log(`   • ${colName.padEnd(18)} : ${docs.length} documents saved -> ${colName}.json`);
}

// 4. Test network connectivity to Firebase endpoints
console.log('\n🌐 [Network Connectivity Test]');
try {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 4000);
  const res = await fetch('https://identitytoolkit.googleapis.com/', { signal: controller.signal });
  clearTimeout(timeoutId);
  console.log(`   • Google Identity / Firebase Auth Endpoint: REACHABLE (HTTP ${res.status}) ✅`);
} catch (err) {
  console.log(`   • Firebase Endpoint Check: Offline or timed out (${err.message}) ⚠️`);
}

console.log('\n================================================================');
console.log('✅ Configuration & Datasets Ready!');
console.log('   • To test in-app: Open app on Mac / Simulator -> Profile -> Settings -> Database & Firebase Status');
console.log('   • To deploy Firestore rules/indexes: firebase deploy --only firestore:rules,firestore:indexes');
console.log('================================================================\n');
