# Platform-Specific Configuration

## Android Setup

### Required Permissions
The app needs camera and storage permissions. These should already be in your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Android Build Configuration
Ensure your `android/app/build.gradle.kts` has proper configuration:
- `compileSdk` 34+
- `targetSdk` 34+
- `minSdk` 24+ (recommended)

### Running on Android
```bash
# Connect Android device or start emulator
flutter run
```

### Building APK for Release
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

## iOS Setup

### Required Permissions
Add these to your `ios/Runner/Info.plist`:

```xml
<dict>
    ...
    <key>NSCameraUsageDescription</key>
    <string>This app needs camera access to recognize traffic signs</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>This app needs photo library access to select images for sign recognition</string>
    ...
</dict>
```

### Build Settings
Ensure your Xcode project has:
- iOS Deployment Target: 12.0+
- Swift Language Version: 5.0+

### Running on iOS
```bash
# For iOS Simulator
flutter run

# For physical device
flutter run -d <device-id>
```

### Building IPA for Release
```bash
flutter build ipa --release
# Output: build/ios/ipa/
```

## Troubleshooting Common Issues

### Issue: "TensorFlow Lite not found"
**Solution:**
```bash
flutter pub get
flutter clean
flutter pub get
flutter run
```

### Issue: Camera permission denied
**Android**: Go to Settings → Apps → [App Name] → Permissions → Enable Camera
**iOS**: Settings → [App Name] → Camera → Allow

### Issue: Image picker not working
Ensure you have:
- Camera/Gallery permissions granted
- At least one camera or image available on device

### Issue: Build fails with Gradle error
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: iOS build fails
**Solution:**
```bash
rm -rf ios/Pods
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
flutter run
```

## Testing the App

### Test with Sample Traffic Sign Images
1. Take a photo of a traffic sign or use a traffic sign image from the gallery
2. The app should display:
   - The recognized sign name
   - Confidence percentage (should be high for clear signs)

### Expected Results
- **Clear sign photos**: 85-99% confidence
- **Angled photos**: 70-90% confidence  
- **Low quality images**: 50-80% confidence
- **Non-traffic-sign images**: Variable confidence with likely wrong classification

## Performance Optimization

### For Better Results:
- Use well-lit photos
- Ensure sign is centered and clear
- Avoid extreme angles
- Make sure sign takes up significant portion of image

### Device Compatibility
- Works on Android 6.0+ (API 24+)
- Works on iOS 12.0+
- Requires ~50MB of storage for model and app
- Runs best on devices with 2GB+ RAM

## Debugging

### Enable verbose logging
```bash
flutter run -v
```

### Check device logs
```bash
# Android
adb logcat | grep flutter

# iOS
log stream --predicate 'eventMessage contains[cd] "flutter"'
```

### Common Log Messages
- `Model initialized successfully` - Model loaded correctly
- `Image classified as: [label]` - Classification complete
- Permission errors - User needs to grant permissions
