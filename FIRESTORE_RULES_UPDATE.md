# Firestore Security Rules Update for Activity Logging

## Required Rules for `activityLogs` Collection

You need to add security rules for the new `activityLogs` collection in your Firebase Console.

### Steps to Update Rules:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project (interprep-585db)
3. Navigate to: **Firestore Database** > **Rules** tab
4. Add the following rules for the `activityLogs` collection

### Security Rules to Add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... your existing rules ...
    
    // Activity Logs Collection
    match /activityLogs/{logId} {
      // Users can read their own activity logs
      // Users can create activity logs (for themselves)
      // Admins can read all activity logs
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin');
      
      // Any authenticated user can create activity logs (will be validated by service)
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
      
      // Only admins can update or delete activity logs
      allow update, delete: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // ... rest of your existing rules ...
  }
}
```

### Complete Rules Example (if you're starting fresh):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is admin
    function isAdmin() {
      return request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      allow update, delete: if isAdmin();
    }
    
    // Sessions collection
    match /sessions/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if isAdmin();
    }
    
    // Activity Logs Collection
    match /activityLogs/{logId} {
      // Users can read their own activity logs
      // Admins can read all activity logs
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.userId || isAdmin());
      
      // Any authenticated user can create activity logs (validated by service)
      allow create: if request.auth != null && 
        request.auth.uid == request.resource.data.userId;
      
      // Only admins can update or delete activity logs
      allow update, delete: if isAdmin();
    }
    
    // User Progress collection
    match /userProgress/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if isAdmin();
    }
    
    // Files collection
    match /files/{fileId} {
      allow read, write: if request.auth != null;
    }
    
    // Goals collection
    match /goals/{goalId} {
      allow read, write: if request.auth != null && 
        resource.data.userId == request.auth.uid;
    }
    
    // Add other collections as needed...
  }
}
```

### Important Notes:

1. **Indexes Required**: The activity logs collection uses queries that may require composite indexes. Firebase will prompt you to create them automatically when you first run the query, or you can create them manually in the Firebase Console under Firestore Database > Indexes.

   Required indexes:
   - Collection: `activityLogs`
   - Fields: `userId` (Ascending), `timestamp` (Descending)
   - Fields: `type` (Ascending), `timestamp` (Descending)

2. **Testing Rules**: After updating rules, test them in the Firebase Console using the Rules Playground.

3. **Deployment**: If you're using Firebase CLI, you can also create a `firestore.rules` file in your project root and deploy it using:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Security Considerations:

- Users can only create activity logs for themselves (validated by `userId` match)
- Users can only read their own activity logs
- Admins can read all activity logs for monitoring
- Only admins can update or delete logs (for data integrity)




