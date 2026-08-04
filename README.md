# CleanZone Mobile App

CleanZone is a Flutter-based mobile application that connects **customers** who need house cleaning services with **cleaners** who can accept and complete jobs. The app is built with Firebase as its backend for authentication, data storage, and file uploads.

## Features

### Customer
- Sign up / log in
- Post a cleaning job with details and house photos
- View ongoing jobs and job status
- Receive notifications
- Leave and view reviews
- Edit profile

### Cleaner
- Sign up / log in
- Browse and find available jobs
- Accept and manage ongoing jobs
- Receive notifications
- Leave and view reviews
- Edit profile

## Tech Stack

- **Framework:** Flutter (Dart)
- **Backend:** Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **Image handling:** image_picker
- **Platforms:** Android, iOS, Web, Windows, Linux, macOS

## Project Structure

```
lib/
├── cleaner/        # Cleaner-facing screens (home, jobs, profile, reviews, notifications)
├── customer/        # Customer-facing screens (home, post job, ongoing jobs, profile, reviews)
├── login/           # Authentication screens (login, signup, role selection)
├── firebase_options.dart
└── main.dart
```

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.7.0)
- A Firebase project (Firestore, Auth, and Storage enabled)
- Android Studio / Xcode for mobile builds

### Setup

1. Clone the repository
   ```bash
   git clone https://github.com/suneraz/CleanZone-Mobile-App.git
   cd CleanZone-Mobile-App
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Configure Firebase
   This project uses FlutterFire. Generate your own `firebase_options.dart` by running:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   > **Note:** `firebase_options.dart` is excluded from version control since it contains project-specific Firebase keys. You must generate it locally against your own Firebase project.

4. Run the app
   ```bash
   flutter run
   ```

## Security Note

API keys in Firebase client config files (like `firebase_options.dart`) identify a Firebase project rather than acting as secret credentials, but access control is enforced through **Firestore Security Rules** and **API key restrictions** in Google Cloud Console — both of which should be configured before deploying this app to production.

## License

This project was developed as part of an academic assignment (CIS5006 - Mobile and Web Technologies).
