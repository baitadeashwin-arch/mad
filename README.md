# AntiSocial: AI-Powered Social Discovery & Party Companion

<p float="left">
  <img src="https://github.com/alejandro-piguave/tinder-clone-ios-public/blob/main/screenshots/swiping_example.gif" width="250">
  <img src="https://github.com/alejandro-piguave/tinder-clone-ios-public/blob/main/screenshots/create_profile.gif" width="250" />
  <img src="https://github.com/alejandro-piguave/tinder-clone-ios-public/blob/main/screenshots/create_profile_dark.gif" width="250" /> 
</p>

**AntiSocial** is a next-generation native iOS social discovery application built with **SwiftUI**, **Firebase**, and modern iOS technologies using the **MVVM** architectural pattern. Designed for building real-world social connections, finding event companions, and discovering local scenes.

---

## 🌟 Key Social Discovery Features

### 1. Connection Modes
Users can select their preferred social discovery mode:
* **🤝 Friend Mode**: Connect with peers for campus life, study groups, coffee meetups, and shared hobbies.
* **🎉 Party Mode**: Find crew members for nightlife, concerts, house parties, festivals, and weekend outings.
* **🌟 Social & Party (Both)**: Open to all social discovery opportunities.

### 2. College & Local Communities
* Tag your university, campus, or local neighborhood community to discover peers nearby.

### 3. Shared Interests & Vibes
* Select and display shared interest chips (e.g., *House Parties*, *Live Music & Concerts*, *Nightlife & Clubs*, *Gaming*, *Fitness*, *Tech & Startups*).

---

## 📱 Application Screens & Flows

### Login & Onboarding
* **Google Sign-In**: Streamlined authentication flow with Firebase token exchange and session management.
* **Social Profile Creation**:
  * Upload at least two profile pictures (via Camera or Photo Library).
  * Choose your **Connection Mode** (Friend Mode / Party Mode / Both).
  * Specify your **College / Campus / Community**.
  * Pick your **Shared Interests & Vibes**.
  * Personal information (Name, Birthdate, Bio up to 500 characters).

### Social Discovery (Deck)
* Browse nearby social profiles with smooth gesture-driven cards.
* Switch between a user's photos with intuitive story-like progress bars and tap zones.
* Badges prominently display connection mode, college community, and interest chips.
* **CONNECT** (Right Swipe / Sparkles) or **PASS** (Left Swipe / X).
* Reciprocal connections trigger the **"It's a Connection!"** celebration modal.

### Profile Editing
* Update your Connection Mode, College/Community, Interests, Bio, and Photos at any time.
* Drag-and-drop photo grid reordering and replacement.

### Real-Time Connections & Chat
* Dedicated **Connections** directory showcasing mutual connections with mode badges.
* Real-time 1-on-1 messaging powered by Cloud Firestore snapshot listeners and auto-scrolling conversation feeds.

---

## 🛠️ Architecture & Technologies

* **UI**: SwiftUI (iOS 15.0+)
* **Pattern**: Model-View-ViewModel (MVVM) with Repository & Data Source layers
* **Backend**: Firebase Authentication (Google Sign-In), Cloud Firestore, Cloud Storage
* **Concurrency**: Swift Structured Concurrency (`async`/`await`, `TaskGroup`, `AsyncThrowingStream`)
* **Localization**: Full English (`en`) and Spanish (`es`) localization
* **Dark Mode**: Native adaptive color scheme support

---

> **Note**: To connect to your own Firebase project, place your `GoogleService-Info.plist` inside the project root and ensure the URL Schemes match your Google OAuth Client ID.
