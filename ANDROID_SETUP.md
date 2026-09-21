# Android Setup Guide - InterPrep

Is guide mein aapko Android par InterPrep app chalane ke liye step-by-step instructions milenge.

## Prerequisites (Pehle se Required)

1. **Flutter SDK** installed
2. **Android Studio** installed
3. **Android SDK** (minimum API 21)
4. **Java JDK** (version 8 ya higher)
5. **Physical Android device** ya **Android Emulator**

## Step 1: Flutter Doctor Check

Pehle verify karein ke sab kuch properly setup hai:

```bash
flutter doctor
```

Ensure ke yeh sab green ho:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ Android Studio
- ✅ Connected device (physical ya emulator)

## Step 2: Android Dependencies Install

```bash
# Android dependencies update karein
cd android
./gradlew clean
cd ..
```

## Step 3: Flutter Packages Install

```bash
# Project root directory mein
flutter pub get
```

## Step 4: Android Permissions Check

`android/app/src/main/AndroidManifest.xml` mein yeh permissions already honi chahiye:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

## Step 5: Firebase Configuration

1. **google-services.json** file check karein:
   - `android/app/google-services.json` file exist karti hai ya nahi
   - Agar nahi hai, to Firebase Console se download karein

2. **Firebase Project Setup:**
   - Firebase Console mein jayein
   - Android app add karein (package name: `com.example.interprep`)
   - `google-services.json` download karein
   - File ko `android/app/` folder mein copy karein

## Step 6: Build aur Run

### Option A: Physical Device (Recommended)

1. **USB Debugging Enable:**
   - Phone settings → Developer Options → USB Debugging ON
   - Phone ko computer se connect karein

2. **Device Check:**
   ```bash
   flutter devices
   ```
   Aapka device list mein dikhna chahiye

3. **Run App:**
   ```bash
   flutter run
   ```

### Option B: Android Emulator

1. **Emulator Start:**
   - Android Studio → Tools → Device Manager
   - Koi emulator create/start karein (minimum API 21)

2. **Run App:**
   ```bash
   flutter run
   ```

## Step 7: Build APK (Release)

Release APK banane ke liye:

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

APK file location: `build/app/outputs/flutter-apk/app-release.apk`

## Common Issues aur Solutions

### Issue 1: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue 2: "SDK location not found"
**Solution:**
- Android Studio open karein
- SDK location note karein
- `android/local.properties` file mein add karein:
  ```
  sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk
  ```

### Issue 3: "Audio recording not working"
**Solution:**
- AndroidManifest.xml mein RECORD_AUDIO permission check karein
- Runtime permission request code check karein
- Android 6.0+ par runtime permissions required hain

### Issue 4: "Firebase connection failed"
**Solution:**
- `google-services.json` file verify karein
- Internet permission check karein
- Firebase project settings verify karein

### Issue 5: "Package name mismatch"
**Solution:**
- `android/app/build.gradle` mein `applicationId` check karein
- Firebase Console mein same package name use karein

## Audio Recording/Playback for Android

Android par audio recording ke liye:
- `record` package Android par automatically kaam karta hai
- `audioplayers` package Android par native audio playback use karta hai
- Runtime permissions automatically handle hote hain

## Testing Checklist

- [ ] App successfully install hoti hai
- [ ] Firebase authentication kaam karta hai
- [ ] File picker (PDF/PPTX) kaam karta hai
- [ ] Audio recording kaam karta hai
- [ ] Audio playback kaam karta hai
- [ ] Questions generate hote hain
- [ ] Practice session properly load hoti hai
- [ ] Feedback screen properly display hota hai

## Performance Tips

1. **Release Mode Use:**
   ```bash
   flutter run --release
   ```

2. **ProGuard Enable (Optional):**
   - `android/app/build.gradle` mein ProGuard rules add karein

3. **Minify Resources:**
   - Release build automatically resources minify karta hai

## Next Steps

Agar koi issue aaye:
1. `flutter doctor -v` run karein
2. Console logs check karein
3. Android Studio mein Logcat check karein
4. GitHub issues check karein

## Additional Resources

- [Flutter Android Setup](https://docs.flutter.dev/get-started/install/windows)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Android Permissions](https://developer.android.com/training/permissions/requesting)












