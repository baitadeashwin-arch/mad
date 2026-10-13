# AntiSocial — Final Setup & Deployment

The Nearby Mode and Party Mode features are fully implemented and integrated. 
Because you are deploying to a real device, there are a few manual configuration steps required that cannot be committed to source control (such as private API keys and Firebase credentials).

### 1. Firebase Configuration (Blocking)
- **What:** Add `GoogleService-Info.plist`.
- **Where:** Download it from your Firebase Console (Project Settings > General > Your Apps) and place it in the `tinder-clone/` directory. Ensure it is added to the Xcode target.
- **Why:** The app will crash on launch if Firebase cannot initialize.

### 2. Firestore Deployment (Required)
- **What:** Deploy Security Rules and Indexes.
- **Where:** In your terminal, using the Firebase CLI at the project root:
  ```bash
  firebase deploy --only firestore:rules
  firebase deploy --only firestore:indexes
  ```
- **Why:** The new `firestore.rules` protect users' location privacy. The `firestore.indexes.json` contains the composite indexes required for querying nearby parties and filtering party invitations.

### 3. Apple Capabilities (Required)
- **What:** Enable MapKit and Push Notifications capabilities.
- **Where:** In Xcode > select your project target > "Signing & Capabilities" tab.
- **Why:** MapKit requires the capability to render the rich `NearbyMapView`. Push Notifications are required if you intend to transition `NotificationCenterSupport` from local to remote APNs pushes.

### 4. AI Service (Optional)
- **What:** Configure the real AI endpoint.
- **Where:** Add `ANTISOCIAL_AI_ENDPOINT` to your `Info.plist` (or an `.xcconfig` file).
- **Why:** The `AIService` currently uses a deterministic local fallback for conversation starters, ice-breakers, and activity suggestions. Providing the endpoint will seamlessly activate the real `RemoteAIService`.

### 5. Final Xcode Build
- **What:** Clean and Build.
- **Where:** In Xcode, run `Cmd + Shift + K` (Clean) followed by `Cmd + B` (Build).
- **Why:** Ensures all the newly registered Swift files (29+ files) in the `project.pbxproj` are freshly compiled.
