# Firebase Authentication Setup

## Enable Email/Password Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/project/scoutvista-efe76/authentication)
2. Click on "Authentication" in the left sidebar
3. Click on "Get started" if not already done
4. Go to the "Sign-in method" tab
5. Click on "Email/Password"
6. Enable "Email/Password" provider
7. Click "Save"

## Enable Google Sign-In (Optional)

1. In the same "Sign-in method" tab
2. Click on "Google"
3. Enable the Google provider
4. Add your project's support email
5. Click "Save"

## Configure App Check (Optional)

1. Go to [App Check](https://console.firebase.google.com/project/scoutvista-efe76/appcheck)
2. Click "Get started"
3. Register your app
4. Choose "reCAPTCHA Enterprise" for testing
5. Follow the setup instructions

## Test Authentication

After enabling authentication:
1. Run the app
2. Try to sign in with email/password
3. Check Firebase Console > Authentication > Users for new users

## Common Issues

- **"This operation is not allowed"**: Authentication provider not enabled
- **"No AppCheckProvider installed"**: App Check not configured (warning only)
- **Google Sign-In Error**: Google provider not enabled or SHA-1 not configured
