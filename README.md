# SoilSocial 🌾

A farming social network built with Flutter and Firebase. Connect with fellow farmers, share knowledge, trade produce, and stay updated with weather and community events.

## Features

- **Authentication** — Email/password & Google Sign-In with email verification
- **Social Feed** — Create posts with images, tags, crop types; like & comment
- **User Profiles** — Bio, location, crops grown, farming techniques
- **Connections** — Send/accept/reject connection requests (LinkedIn-style networking)
- **Messaging** — Real-time one-on-one chat with unread indicators
- **Marketplace** — List and browse food/produce and farming equipment
- **Events** — Create events with RSVP, date/time, location, and attendee limits
- **Crop Groups** — Join or create crop-specific communities
- **Notifications** — Real-time notification feed with unread badges
- **Weather** — Current weather widget via OpenWeather API
- **Search** — Global search across users, posts, products, and events

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Storage) |
| State Management | Provider (ChangeNotifier) |
| Navigation | GoRouter |
| Image Caching | CachedNetworkImage |
| Weather API | OpenWeatherMap |

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── firebase_options.dart      # Firebase configuration
├── config/
│   ├── router.dart            # GoRouter setup with auth guards
│   └── theme.dart             # Green farming-themed Material 3
├── models/
│   ├── user_model.dart
│   ├── post_model.dart
│   ├── comment_model.dart
│   ├── product_model.dart
│   ├── crop_group_model.dart
│   ├── message_model.dart
│   ├── notification_model.dart
│   └── event_model.dart
├── services/
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── user_service.dart
│   ├── post_service.dart
│   ├── product_service.dart
│   ├── message_service.dart
│   ├── notification_service.dart
│   ├── event_service.dart
│   ├── group_service.dart
│   └── weather_service.dart
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── main_shell.dart
│   ├── auth/
│   ├── dashboard/
│   ├── profile/
│   ├── posts/
│   ├── network/
│   ├── messages/
│   ├── marketplace/
│   ├── events/
│   ├── groups/
│   ├── notifications/
│   └── search/
└── widgets/
    ├── post_card.dart
    ├── comment_section.dart
    └── weather_card.dart
```

## Getting Started

### Prerequisites

- Flutter SDK ≥ 3.11.0
- Firebase project with Auth, Firestore, and Storage enabled
- Android Studio / VS Code with Flutter extension

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/soilsocial.git
   cd soilsocial
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** and **Google** sign-in methods
   - Create a **Firestore Database** (start in test mode)
   - Enable **Firebase Storage** (start in test mode)
   - Run `flutterfire configure` or replace `lib/firebase_options.dart` with your config

4. **Run the app**
   ```bash
   flutter run
   ```

### Platform-Specific Notes

- **Android Google Sign-In**: Add your debug SHA-1 key to Firebase Console → Project Settings → Android app:
  ```bash
  cd android && ./gradlew signingReport
  ```
- **Web**: `flutter run -d chrome`

## Firestore Collections

| Collection | Description |
|-----------|-------------|
| `users` | User profiles, connections, settings |
| `posts` | Social feed posts |
| `comments` | Post comments (subcollection-style) |
| `products` | Marketplace listings |
| `groups` | Crop-specific communities |
| `messages` | Direct messages |
| `conversations` | Conversation metadata |
| `notifications` | User notifications |
| `events` | Community events |

## License

This project is for educational and personal use.
