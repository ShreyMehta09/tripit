# ✈️ TripIt — AI-Powered Travel Planner

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Groq_AI-000000?style=for-the-badge&logo=ai&logoColor=white" alt="Groq AI"/>
</p>

<p align="center">
  <b>Your AI Travel Companion</b> — Plan personalised trip itineraries in seconds with the power of AI.
</p>

---

## 📖 About

**TripIt** is a cross-platform Flutter application that leverages **Groq AI (LLaMA 3.1)** to generate detailed, personalised travel itineraries. Simply enter your destination, budget, travel dates, and preferences — and TripIt crafts a comprehensive day-by-day plan complete with accommodation options, budget breakdowns, packing lists, and local tips.

## ✨ Features

| Feature | Description |
|---|---|
| 🤖 **AI Itinerary Generation** | Powered by Groq's LLaMA 3.1 model for fast, detailed travel plans |
| 🔐 **Authentication** | Email/Password & Google Sign-In via Firebase Auth |
| 💾 **Cloud Storage** | All trips are saved to Cloud Firestore with real-time sync |
| 🔔 **Push Notifications** | Local + FCM notifications when a new trip is created |
| 📧 **Email Confirmations** | Automated HTML itinerary email sent via SMTP on trip creation |
| ✏️ **Trip Management** | Create, view, edit, and delete trips with swipe actions |
| 🧳 **Travel Preferences** | Customise by travel style, interests, and special requirements |
| 💡 **Smart Suggestions** | AI-suggested destinations based on budget, duration, and interests |
| 👤 **User Profiles** | Editable profiles with display name, bio, and location |
| 🌙 **Dark Mode UI** | Sleek Material 3 dark theme with smooth animations |

## 🏗️ Architecture

```
lib/
├── main.dart                        # App entry point & theme configuration
├── firebase_options.dart            # Auto-generated Firebase config
├── models/
│   └── trip_model.dart              # TripModel & TripRequest data classes
├── screens/
│   ├── splash_screen.dart           # Animated splash with auth routing
│   ├── auth/
│   │   ├── login_screen.dart        # Login (Email/Password + Google)
│   │   └── signup_screen.dart       # Registration screen
│   ├── home/
│   │   └── home_screen.dart         # Dashboard with trip lists
│   ├── trip/
│   │   ├── plan_trip_screen.dart    # AI trip planning form
│   │   ├── trip_result_screen.dart  # Generated itinerary display
│   │   ├── trip_detail_screen.dart  # Saved trip details view
│   │   └── edit_trip_screen.dart    # Edit existing trips
│   └── profile/
│       └── profile_screen.dart      # User profile management
└── services/
    ├── auth_service.dart            # Firebase Auth + Google Sign-In
    ├── gemini_service.dart          # Groq / LLaMA 3.1 API integration
    ├── trip_service.dart            # Firestore CRUD for trips
    ├── user_service.dart            # Firestore user profile management
    └── notification_service.dart    # FCM, local notifications & email
```

## 🛠️ Tech Stack

- **Framework:** Flutter 3 (Dart 3.10+)
- **UI:** Material 3 with custom dark theme
- **State Management:** Provider
- **Backend:** Firebase (Auth, Cloud Firestore)
- **AI:** Groq API — LLaMA 3.1 8B Instant
- **Notifications:** Firebase Cloud Messaging + Flutter Local Notifications
- **Email:** SMTP via `mailer` package (Gmail App Password)
- **Animations:** `flutter_animate`

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.10
- A Firebase project with **Authentication** and **Cloud Firestore** enabled
- A [Groq API key](https://console.groq.com/) for AI itinerary generation
- *(Optional)* Gmail App Password for email notifications

### 1. Clone the Repository

```bash
git clone https://github.com/ShreyMehta09/tripit.git
cd tripit
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Environment Variables

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key_here

# Optional — for email notifications
SMTP_EMAIL=your_email@gmail.com
SMTP_PASSWORD=your_gmail_app_password
```

> ⚠️ **Never commit the `.env` file.** It is already included in `.gitignore`.

### 4. Set Up Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com/)
2. Enable **Email/Password** and **Google** sign-in providers under Authentication
3. Create a **Cloud Firestore** database
4. Run the FlutterFire CLI to configure your project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

5. Deploy Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

### 5. Run the App

```bash
flutter run
```

## 🔒 Firestore Security Rules

TripIt enforces user-level data isolation — users can only access their own data:

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /trips/{tripId} {
      allow read, update, delete: if request.auth != null
        && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null
        && request.resource.data.userId == request.auth.uid;
    }
  }
}
```

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `firebase_core` | Firebase initialisation |
| `firebase_auth` | Authentication |
| `cloud_firestore` | NoSQL database |
| `google_sign_in` | Google OAuth |
| `google_generative_ai` | Generative AI SDK |
| `http` | REST API calls to Groq |
| `provider` | State management |
| `flutter_dotenv` | Environment variables |
| `intl` | Date formatting |
| `flutter_slidable` | Swipe-to-delete actions |
| `flutter_animate` | Smooth animations |
| `firebase_messaging` | Push notifications |
| `flutter_local_notifications` | Device notifications |
| `mailer` | SMTP email sending |

## 🎨 Screenshots

> *Coming soon — screenshots of the dark-themed UI showcasing the splash screen, trip planner, AI-generated itinerary, and profile page.*

## 📄 License

This project is for educational purposes. Built as part of a Mobile Application Development course.

---

<p align="center">
  Made with ❤️ using Flutter & AI
</p>
