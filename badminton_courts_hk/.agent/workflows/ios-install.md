---
description: how to install the badminton_courts_hk app to an iPhone
---

To install the app on your physical iPhone, follow these steps:

### 1. Prerequisites
- Ensure you have **Xcode** installed on your Mac.
- Open your terminal and navigate to the project directory:
  `cd /Users/aidanwong/Projects/SmartCheckCheungC/badminton_courts_hk`

### 2. Prepare the iOS Project
Run the following command to ensure all dependencies are ready:
```bash
flutter pub get
cd ios
pod install
cd ..
```

### 3. Open in Xcode
Open the iOS part of the project in Xcode:
```bash
open ios/Runner.xcworkspace
```

### 4. Setup Signing (Crucial)
1. In Xcode, click on the **Runner** project in the left sidebar (the blue icon at the top).
2. Select the **Runner** target in the list.
3. Go to the **Signing & Capabilities** tab.
4. Ensure **Automatically manage signing** is checked.
5. Select your **Team**/Apple ID. 
   > [!IMPORTANT]
   > If you see the error **"No profiles found"**, Xcode just needs to create one for the new ID. Selecting your Team should trigger this. 
   > 
   > If it still fails, the Bundle Identifier might be taken. Try changing it slightly (e.g., `com.smartcheck.badminton.hk.YOURNAME`) to make it truly unique.

### 5. Connect and Run
1. Connect your iPhone to your Mac via USB.
2. If your iPhone asks "Trust this Computer?", tap **Trust**.
3. In Xcode's top toolbar, select your physical iPhone as the deployment target.
4. Press the **Play button (Run)** in Xcode, OR run this command in your terminal:
   ```bash
   flutter run -d [YOUR_DEVICE_ID]
   ```
   *(To find your device ID, run `flutter devices`)*

### 6. Trust the Developer on iPhone
The first time you install, the app might not open.
1. On your iPhone, go to **Settings > General > VPN & Device Management**.
2. Tap on your Apple ID under "Developer App".
3. Tap **Trust [Your Apple ID]**.
4. Open the app!
