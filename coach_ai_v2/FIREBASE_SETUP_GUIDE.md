# 🔥 Firebase Setup Guide - Coach AI v2

## Current Status ✅
- **Model Path Fixed**: `pushUp_version2.tflite` now loads correctly
- **App Running**: Video processing working with mock data
- **Firebase Issues**: Storage 404, Firestore PERMISSION_DENIED

## Firebase Console Setup Steps

### **Step 1: Enable Firestore API** 🗄️
1. **Go to**: https://console.firebase.google.com/project/gradproject-2531f
2. **Navigate to**: Firestore Database
3. **Click**: "Create database"
4. **Choose**: "Start in test mode" (for development)
5. **Select**: Location (choose closest to your users)
6. **Click**: "Done"

### **Step 2: Enable Firebase Storage** 📦
1. **Navigate to**: Storage
2. **Click**: "Get started"
3. **Choose**: "Start in test mode" (for development)
4. **Select**: Location (same as Firestore)
5. **Click**: "Done"

### **Step 3: Verify APIs in Google Cloud Console** ☁️
1. **Go to**: https://console.cloud.google.com/apis/library?project=gradproject-2531f
2. **Search and Enable**:
   - ✅ Cloud Firestore API
   - ✅ Firebase Storage API
   - ✅ Firebase Authentication API
   - ✅ Firebase Cloud Functions API (for future use)

### **Step 4: Update Security Rules** 🔒

#### **Firestore Rules** (Copy to Firebase Console → Firestore → Rules):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own assessments
    match /assessments/{assessmentId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    
    // SAI submissions are read-only for users
    match /sai_submissions/{submissionId} {
      allow read: if request.auth != null && request.auth.uid == resource.data.userId;
      allow write: if false; // Only Cloud Functions can write
    }
    
    // User profiles
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

#### **Storage Rules** (Copy to Firebase Console → Storage → Rules):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only upload to their own folder
    match /videos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public read access for shared content (if needed)
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if false; // Only admins can write
    }
  }
}
```

### **Step 5: Test Firebase Connection** 🧪
After completing the above steps, test the app:
1. **Upload a video** in the app
2. **Check logs** for successful Firebase operations
3. **Verify** no more 404 or PERMISSION_DENIED errors

## Expected Results After Setup

### **Before Setup** ❌
```
[ERROR] Firebase Storage upload failed | Error: [firebase_storage/object-not-found] No object exists at the desired reference.
[WARNING] Firestore: Stream closed with status: Status{code=PERMISSION_DENIED, description=Cloud Firestore API has not been used in project gradproject-2531f before or it is disabled}
```

### **After Setup** ✅
```
[INFO] Firebase Storage upload completed successfully
[INFO] Firestore document created successfully
[INFO] Firebase upload completed successfully | Data: {documentId: abc123, videoUrl: https://storage.googleapis.com/...}
```

## Troubleshooting

### **If Firestore Still Shows PERMISSION_DENIED**:
1. **Wait 5-10 minutes** for API propagation
2. **Check API status** in Google Cloud Console
3. **Verify project ID** matches `gradproject-2531f`

### **If Storage Still Shows 404**:
1. **Check bucket name** in Firebase Console
2. **Verify storage rules** are deployed
3. **Ensure location** matches Firestore location

### **If Authentication Fails**:
1. **Enable Authentication** in Firebase Console
2. **Add Google Sign-In** provider
3. **Configure OAuth consent screen**

## Next Steps After Firebase Setup

1. **Test Real Analysis**: Upload videos and verify real pose detection
2. **Configure App Check**: Add security for production
3. **Set up Cloud Functions**: For advanced AI processing
4. **Monitor Usage**: Track API calls and storage usage

## Security Considerations

### **Development Mode** (Current):
- ✅ **Test rules** allow all authenticated users
- ✅ **Easy setup** for development
- ⚠️ **Not secure** for production

### **Production Mode** (Future):
- 🔒 **Restrictive rules** based on user roles
- 🔒 **App Check** for request validation
- 🔒 **Rate limiting** to prevent abuse

## Cost Monitoring

### **Free Tier Limits**:
- **Firestore**: 50K reads, 20K writes, 20K deletes per day
- **Storage**: 5GB storage, 1GB/day downloads
- **Functions**: 125K invocations, 40K GB-seconds per month

### **Monitoring**:
- **Set up billing alerts** in Google Cloud Console
- **Monitor usage** in Firebase Console
- **Track costs** in Google Cloud Billing

## Success Criteria

✅ **Firebase Setup Complete When**:
- [ ] Firestore API enabled and working
- [ ] Storage API enabled and working
- [ ] Security rules deployed
- [ ] Video uploads succeed
- [ ] Analysis reports saved to Firestore
- [ ] No more 404 or PERMISSION_DENIED errors

## Support Resources

- **Firebase Console**: https://console.firebase.google.com/project/gradproject-2531f
- **Google Cloud Console**: https://console.cloud.google.com/project/gradproject-2531f
- **Firebase Documentation**: https://firebase.google.com/docs
- **Firestore Rules**: https://firebase.google.com/docs/firestore/security/get-started
- **Storage Rules**: https://firebase.google.com/docs/storage/security/get-started

---

**Once Firebase is properly configured, the app will have full cloud functionality for video storage, analysis reports, and user data management!** 🚀✨
