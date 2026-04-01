# SHA-1 Fingerprint Configuration Guide

## Method 1: Using Android Studio (Recommended)

1. **Open Android Studio**
2. **Open your project** (`coach_ai_v2/android`)
3. **Open Gradle panel** (right side)
4. **Navigate to**: `app` → `Tasks` → `android` → `signingReport`
5. **Double-click** `signingReport`
6. **Look for** `Variant: debug` section
7. **Copy the SHA1** value (looks like: `AA:BB:CC:DD:EE:FF:...`)

## Method 2: Using Command Line

### Windows (PowerShell):
```powershell
# Navigate to your project
cd android

# Run gradle signing report
./gradlew signingReport

# Look for the SHA1 in the output under "Variant: debug"
```

### Alternative (if keytool is available):
```powershell
# Find Java installation
where java

# Use keytool (replace with your Java path)
"C:\Program Files\Java\jdk-11\bin\keytool.exe" -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## Method 3: Using Flutter

```bash
# Build debug APK (this will show SHA1 in logs)
flutter build apk --debug

# Look for SHA1 in the build output
```

## Step 2: Add SHA-1 to Firebase Console

1. **Go to Firebase Console**: https://console.firebase.google.com/project/scoutvista-efe76/settings/general
2. **Scroll down** to "Your apps" section
3. **Find your Android app** (`com.example.coach_ai_v2`)
4. **Click the settings icon** (gear icon)
5. **Click "Add fingerprint"**
6. **Paste the SHA-1** you copied
7. **Click "Save"**

## Step 3: Download Updated google-services.json

1. **After adding SHA-1**, download the updated `google-services.json`
2. **Replace** the file in `android/app/google-services.json`
3. **Rebuild** your app

## Step 4: Enable Google Sign-In

1. **Go to Authentication**: https://console.firebase.google.com/project/scoutvista-efe76/authentication
2. **Click "Sign-in method"** tab
3. **Enable "Google"** provider
4. **Add support email**
5. **Save**

## Common SHA-1 Locations

- **Debug keystore**: `%USERPROFILE%\.android\debug.keystore` (Windows)
- **Release keystore**: Usually in `android/app/` directory

## Troubleshooting

- **Error 10**: SHA-1 not configured or Google Sign-In not enabled
- **Package name mismatch**: Check `android/app/google-services.json` matches your app
- **Multiple SHA-1s**: Add both debug and release SHA-1s if needed

## Example SHA-1 Format
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```
