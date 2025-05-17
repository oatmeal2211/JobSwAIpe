# JobSwAIpe

A Flutter job search application with Firebase, Alibaba Cloud Model Studio and Qwen integration.

## Overview

JobSwAIpe is a modern job search application built with Flutter and Firebase. The app allows users to:
- Register and login with email/password authentication
- Browse job listings fetched from Firestore
- View detailed job information
- Save favorite jobs
- Manage their profile

## Getting Started

The complete application is located in the `job_swaipe` directory. Please follow the detailed setup instructions in the [app's README file](job_swaipe/README.md).

## Quick Setup

1. Navigate to the app directory:
   ```bash
   cd job_swaipe
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up Firebase:
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Configure Firebase for your Flutter app:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure --project=<your-firebase-project-id>
     ```
   - Enable Email/Password authentication in Firebase console
   - Set up Firestore database with a "jobs" collection

4. Run the app:
   ```bash
   flutter run
   ```

## Features

- **Authentication**: Secure login and registration with Firebase Auth
- **Job Listings**: Display jobs from Firestore database
- **Job Details**: View comprehensive job information
- **User Profile**: Basic profile management
- **Favorites**: Save jobs for later (UI implementation)

## Technologies Used

- Flutter
- Firebase Authentication
- Cloud Firestore
- Material Design

## Screenshots

(Screenshots will be added when the app is running with Firebase configuration)

## License

This project is licensed under the MIT License.
