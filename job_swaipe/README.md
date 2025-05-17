# JobSwAIpe

A Flutter job search application with Firebase integration.

## Features

- User authentication (login/register) with Firebase Auth
- Job listings from Firestore database
- Job details view
- Profile management
- Save favorite jobs (UI only)

## Prerequisites

- Flutter SDK (latest stable version)
- Firebase account
- Android Studio / VS Code with Flutter plugins
- Android/iOS device or emulator

## Setup Instructions

### 1. Clone the repository

```bash
git clone <repository-url>
cd job_swaipe
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Firebase

#### Create a Firebase project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Once your project is created, click "Continue"

#### Add Firebase to your Flutter app

1. In the Firebase console, click on your project
2. Click the Android icon (to add Android app) or iOS icon (to add iOS app)
3. Follow the setup instructions for each platform:

**For Android:**
- Enter your app's package name (found in `android/app/build.gradle` as `applicationId`)
- Download the `google-services.json` file and place it in the `android/app` directory
- Follow the remaining setup instructions

**For iOS:**
- Enter your app's bundle ID (found in Xcode under the Runner target)
- Download the `GoogleService-Info.plist` file and add it to your Xcode project
- Follow the remaining setup instructions

**For Web:**
- Enter your app's nickname and optionally the hosting domain
- Follow the remaining setup instructions

#### Configure FlutterFire

Use the FlutterFire CLI to configure Firebase for your Flutter app:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This will generate the `firebase_options.dart` file in your project.

### 4. Enable Authentication

1. In the Firebase console, go to "Authentication"
2. Click "Get started"
3. Enable "Email/Password" authentication method

### 5. Set up Firestore Database

1. In the Firebase console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in production mode" or "Start in test mode" (for development)
4. Select a location for your database
5. Create a "jobs" collection with sample job documents, each containing:
   - title (string)
   - company (string)
   - location (string)
   - description (string)
   - salary (string)

Example job document:
```
{
  "title": "Flutter Developer",
  "company": "Tech Corp",
  "location": "Remote",
  "description": "We are looking for an experienced Flutter developer to join our team...",
  "salary": "$80,000 - $100,000"
}
```

### 6. Run the app

```bash
flutter run
```

## Project Structure

- `lib/main.dart` - Entry point of the application
- `lib/screens/` - Contains all screen widgets
  - `auth/` - Authentication screens (login, register)
  - `home_screen.dart` - Main screen after authentication
- `lib/services/` - Service classes
  - `auth_service.dart` - Firebase authentication service

## Troubleshooting

- If you encounter build errors, try:
  ```bash
  flutter clean
  flutter pub get
  ```

- For Firebase connection issues, verify that your configuration files are correctly placed and that your app has internet permissions.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
