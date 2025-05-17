# JobSwAIpe

A Flutter job search application with Firebase and Alibaba Cloud OSS integration.

## Overview

JobSwAIpe is a modern job search application built with Flutter and Firebase. The app allows users to:
- Register and login with email/password authentication
- Browse job listings fetched from Firestore
- View detailed job information
- Save favorite jobs
- Manage their profile
- Upload profile pictures and resumes using Alibaba Cloud OSS

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

4. Set up Alibaba Cloud OSS:
   - Create an Alibaba Cloud account and set up an OSS bucket
   - Create a `.env` file in the root of the `job_swaipe` directory with the following content:
     ```
     ALIBABA_OSS_ENDPOINT=your-endpoint.aliyuncs.com
     ALIBABA_OSS_ACCESS_KEY_ID=your-access-key-id
     ALIBABA_OSS_ACCESS_KEY_SECRET=your-access-key-secret
     ALIBABA_OSS_BUCKET_NAME=your-bucket-name
     ALIBABA_OSS_SECURITY_TOKEN=your-security-token  # Optional
     ```

5. Run the app:
   ```bash
   flutter run
   ```

## Features

- **Authentication**: Secure login and registration with Firebase Auth
- **Job Listings**: Display jobs from Firestore database
- **Job Details**: View comprehensive job information
- **User Profile**: Basic profile management
- **Favorites**: Save jobs for later (UI implementation)
- **File Storage**: Upload and manage files using Alibaba Cloud OSS

## Technologies Used

- Flutter
- Firebase Authentication
- Cloud Firestore
- Alibaba Cloud OSS
- Material Design 3

## Screenshots

(Screenshots will be added when the app is running with Firebase configuration)

## License

This project is licensed under the MIT License.