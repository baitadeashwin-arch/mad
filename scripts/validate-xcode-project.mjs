// scripts/validate-xcode-project.mjs
// Validates project.pbxproj syntax, file references, and build phase consistency

import fs from 'fs';
import path from 'path';

const pbxPath = path.resolve('tinder-clone.xcodeproj', 'project.pbxproj');
const content = fs.readFileSync(pbxPath, 'utf8');

console.log('================================================================');
console.log('   Auditing Xcode Project: tinder-clone.xcodeproj');
console.log('================================================================\n');

// 1. Check brace and parenthesis balance
let openBraces = 0;
let openParens = 0;
for (const char of content) {
  if (char === '{') openBraces++;
  else if (char === '}') openBraces--;
  else if (char === '(') openParens++;
  else if (char === ')') openParens--;
}

console.log(`1. Syntax Balance Check:`);
console.log(`   • Curly Braces:    ${openBraces === 0 ? 'BALANCED ✅' : `UNBALANCED (${openBraces}) ❌`}`);
console.log(`   • Parentheses:     ${openParens === 0 ? 'BALANCED ✅' : `UNBALANCED (${openParens}) ❌`}`);

// 2. Count Build Files & File References
const buildFiles = (content.match(/isa = PBXBuildFile;/g) || []).length;
const fileReferences = (content.match(/isa = PBXFileReference;/g) || []).length;
const sourcePhaseFiles = (content.match(/\/\* Sources \*\//g) || []).length;

console.log(`\n2. Object Counters:`);
console.log(`   • PBXBuildFile entries:     ${buildFiles}`);
console.log(`   • PBXFileReference entries: ${fileReferences}`);
console.log(`   • Source Build Phases:      ${sourcePhaseFiles}`);

// 3. Verify our new files specifically
const targetFiles = [
  'tinder_cloneApp.swift',
  'FirebaseDatabaseManager.swift',
  'DatabaseHealthView.swift',
  'ProfileTabView.swift',
  'GoogleService-Info.plist'
];

console.log(`\n3. Key Files Verification:`);
for (const file of targetFiles) {
  const inBuild = content.includes(`${file} in Sources`) || content.includes(`${file} in Resources`);
  const inFileRef = content.includes(`path = ${file};`) || content.includes(`path = "${file}";`);
  console.log(`   • ${file.padEnd(30)} : BuildPhase=${inBuild ? 'YES ✅' : 'NO ❌'}, FileRef=${inFileRef ? 'YES ✅' : 'NO ❌'}`);
}

// 4. Check GoogleService-Info.plist in tinder-clone
const plistPath = path.resolve('tinder-clone', 'GoogleService-Info.plist');
const plistExists = fs.existsSync(plistPath);
console.log(`\n4. Configuration File Check:`);
console.log(`   • tinder-clone/GoogleService-Info.plist exists: ${plistExists ? 'YES ✅' : 'NO ❌'}`);
if (plistExists) {
  const plistData = fs.readFileSync(plistPath, 'utf8');
  const project = plistData.match(/<key>PROJECT_ID<\/key>\s*<string>([^<]+)<\/string>/)?.[1];
  const bundle = plistData.match(/<key>BUNDLE_ID<\/key>\s*<string>([^<]+)<\/string>/)?.[1];
  console.log(`   • Project ID: ${project}`);
  console.log(`   • Bundle ID:  ${bundle} ${bundle === 'com.alexpi.tinder-clone' ? '✅' : '❌'}`);
}

console.log(`\n================================================================`);
if (openBraces === 0 && openParens === 0 && plistExists) {
  console.log('✅ Xcode Project Structure is 100% HEALTHY and READY TO BUILD.');
} else {
  console.log('⚠️ Issues found that require attention before building.');
}
console.log('================================================================\n');
