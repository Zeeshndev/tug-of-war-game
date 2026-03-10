# Tug of War Mathematics - Setup Guide (Windows Beginner)

## PART 1 — ONE-TIME SETUP

### STEP 1 — Install Flutter
1. Go to: https://flutter.dev/docs/get-started/install/windows
2. Download the Flutter SDK ZIP
3. Extract to C:\flutter  (so C:\flutter\bin\flutter.bat exists)
4. Add C:\flutter\bin to Windows PATH:
   - Search "Environment Variables" in Start menu
   - System Variables > Path > Edit > New > type C:\flutter\bin > OK

Verify: open new Command Prompt and type:  flutter --version

### STEP 2 — Install Android Studio
1. Go to: https://developer.android.com/studio
2. Download and install it (click Next for everything)
3. On first launch: More Actions > SDK Manager
4. Install Android 10.0 API 29 or higher

### STEP 3 — Accept Android Licenses
In Command Prompt:
  flutter doctor --android-licenses
Press y and Enter for every question.

### STEP 4 — Create a Virtual Phone (Emulator)
In Android Studio:
1. Tools > Device Manager > Create Device
2. Choose: Pixel 6 > Next
3. Choose: Android 14 API 34 (download if needed) > Next > Finish
4. Click the Play button to start the emulator

### STEP 5 — Check Everything Works
In Command Prompt:  flutter doctor
You need checkmarks for Flutter and Android toolchain.

---

## PART 2 — RUNNING THE GAME

### STEP 6 — Extract the Project
Extract tug_of_war_flutter_project.zip to somewhere like C:\Projects\tugofwar\

### STEP 7 — Open Command Prompt in the Project
Navigate to the folder in File Explorer, click the address bar, type cmd, press Enter.
OR open Command Prompt and type:  cd C:\Projects\tugofwar

### STEP 8 — Install Packages
  flutter pub get
Wait for: Got dependencies!

### STEP 9 — Start the Emulator
Go to Android Studio > Device Manager > click the Play button on your device.

### STEP 10 — Run the Game!
  flutter run

First run takes 2-4 minutes. The game will appear on the emulator.

---

## COMMON ERRORS

flutter command not found:
  Close and reopen Command Prompt after adding to PATH.

No supported devices found:
  Start the emulator first, or connect a real Android phone with USB debugging.

Gradle build failed:
  Run:  flutter clean
  Then: flutter pub get
  Then: flutter run

SDK not found:
  In Android Studio: File > Project Structure > SDK Location
  Copy that path and create a file android/local.properties with:
  sdk.dir=C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk
  flutter.sdk=C:\\flutter

---

## BUILD AN APK TO SHARE
  flutter build apk --release
APK will be at: build\app\outputs\flutter-apk\app-release.apk
Send this to any Android phone to install directly.

---

## ADDING REAL SOUNDS (Optional)
1. Download free .mp3 sounds from freesound.org or mixkit.co
2. Name them: correct.mp3, wrong.mp3, win.mp3, lose.mp3, key.mp3 etc.
3. Put them in assets/audio/
4. Add to pubspec.yaml dependencies:  just_audio: ^0.9.39
5. Run: flutter pub get
6. Update lib/services/audio_service.dart to load and play them
