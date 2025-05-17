# JobSwAIpe

A Flutter job search application with Firebase and Alibaba Cloud OSS integration.

## Setting Up Alibaba Cloud OSS

JobSwAIpe uses Alibaba Cloud OSS (Object Storage Service) for storing user files such as profile pictures and resumes. To set up Alibaba Cloud OSS in your environment:

1. Create an Alibaba Cloud account if you don't have one already.
2. Create an OSS bucket in your preferred region.
3. Create a `.env` file in the root of the project with the following variables:

```
ALIBABA_OSS_ENDPOINT=your-region.aliyuncs.com
ALIBABA_OSS_ACCESS_KEY_ID=your-access-key-id
ALIBABA_OSS_ACCESS_KEY_SECRET=your-access-key-secret
ALIBABA_OSS_BUCKET_NAME=your-bucket-name
ALIBABA_OSS_SECURITY_TOKEN=your-security-token  # Optional, only needed for STS authentication
```

4. Make sure the `.env` file is included in your `pubspec.yaml` under the assets section:

```yaml
flutter:
  assets:
    - .env
```

## Migrating from Firebase Storage to Alibaba Cloud OSS

If you're migrating an existing project from Firebase Storage to Alibaba Cloud OSS, JobSwAIpe includes a migration tool that will:

1. Download files from Firebase Storage
2. Upload them to Alibaba Cloud OSS
3. Update references in Firestore documents

To run the migration:

1. Make sure both Firebase and Alibaba Cloud OSS are properly configured.
2. Use the `MigrationScreen` component in your app, or run the migration tool directly.

## Features

- **User Authentication**: Email/password login and registration
- **File Storage**: Upload and manage profile pictures and resumes using Alibaba Cloud OSS
- **Job Listings**: Browse job listings with filter options
- **User Profile**: Manage personal information and job preferences
- **Onboarding Flow**: Collect user preferences during initial setup

## Getting Started

1. Clone this repository
2. Create a Firebase project and configure it for your app
3. Set up Alibaba Cloud OSS as described above
4. Run `flutter pub get` to install dependencies
5. Run the app with `flutter run`

## Implementation Details

The project uses a direct integration with Alibaba Cloud OSS API through the Dio HTTP package, implementing:

- File upload
- File deletion
- Generation of temporary signed URLs for file access
- Custom MIME type detection for various file formats

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

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
3. Follow the setup instructions for each platform

#### Configure FlutterFire

Use the FlutterFire CLI to configure Firebase for your Flutter app:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-firebase-project-id>
```

This will generate the `firebase_options.dart` file in your project.

### 4. Set up Environment Variables

Create a `.env` file in the root of your project with the following Firebase configuration:

```
# Firebase Web Configuration
FIREBASE_WEB_API_KEY=your_web_api_key
FIREBASE_WEB_APP_ID=your_web_app_id
FIREBASE_WEB_MESSAGING_SENDER_ID=your_web_messaging_sender_id
FIREBASE_WEB_PROJECT_ID=your_web_project_id
FIREBASE_WEB_AUTH_DOMAIN=your_web_auth_domain
FIREBASE_WEB_STORAGE_BUCKET=your_web_storage_bucket
FIREBASE_WEB_MEASUREMENT_ID=your_web_measurement_id

# Firebase Android Configuration
FIREBASE_ANDROID_API_KEY=your_android_api_key
FIREBASE_ANDROID_APP_ID=your_android_app_id
FIREBASE_ANDROID_MESSAGING_SENDER_ID=your_android_messaging_sender_id
FIREBASE_ANDROID_PROJECT_ID=your_android_project_id
FIREBASE_ANDROID_STORAGE_BUCKET=your_android_storage_bucket

# Firebase iOS Configuration
FIREBASE_IOS_API_KEY=your_ios_api_key
FIREBASE_IOS_APP_ID=your_ios_app_id
FIREBASE_IOS_MESSAGING_SENDER_ID=your_ios_messaging_sender_id
FIREBASE_IOS_PROJECT_ID=your_ios_project_id
FIREBASE_IOS_STORAGE_BUCKET=your_ios_storage_bucket
FIREBASE_IOS_BUNDLE_ID=your_ios_bundle_id
```

Replace the placeholder values with your actual Firebase configuration.

### 5. Enable Authentication

1. In the Firebase console, go to "Authentication"
2. Click "Get started"
3. Enable "Email/Password" authentication method

### 6. Set up Firestore Database

1. In the Firebase console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in production mode" or "Start in test mode" (for development)
4. Select a location for your database
5. Create a "users" collection for storing user data
6. Create a "jobs" collection for job listings

### 7. Set up Firebase Storage

1. In the Firebase console, go to "Storage"
2. Click "Get started"
3. Choose security rules (start with test mode for development)
4. This will be used to store profile pictures and resumes

### 8. Add a logo image

1. Add your logo image to the `assets/images` directory with the name `jobswaipe_logo.png`

### 9. Run the app

```bash
flutter run
```

## App Flow

1. **Login/Registration**: Users can create an account or log in
2. **Onboarding**: New users go through a 4-step onboarding process:
   - Job type selection
   - Employment type and years of experience
   - Location preferences
   - Skills selection
3. **Home Screen**: Browse job listings
4. **Profile**: View and edit profile information

## Project Structure

- `lib/main.dart` - Entry point of the application
- `lib/screens/` - Contains all screen widgets
  - `auth/` - Authentication screens (login, register)
  - `onboarding/` - Onboarding screens
  - `home_screen.dart` - Main screen after authentication
- `lib/services/` - Service classes
  - `auth_service.dart` - Firebase authentication and user data service
- `lib/firebase_options.dart` - Firebase configuration

## Security

- API keys and secrets are stored in the `.env` file (not committed to version control)
- Firebase Authentication is used for secure user authentication
- Firestore security rules should be set up to protect user data

## License

This project is licensed under the MIT License - see the LICENSE file for details.
