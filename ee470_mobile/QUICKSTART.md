# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Install Dependencies
```bash
cd c:\coding\flutter\ee470_mobile
flutter pub get
```

### Step 2: Run the App
```bash
# Run on connected device or emulator
flutter run
```

### Step 3: Test the App
1. Tap **"Take Photo"** to capture a traffic sign with your camera
   - Or tap **"Pick from Gallery"** to select an existing image
2. The app automatically processes the image
3. View the recognized sign name and confidence percentage

## 📱 What You Can Do

✅ **Take Photos**: Capture traffic signs with your device camera
✅ **Upload Images**: Choose images from your device gallery  
✅ **Get Predictions**: Get instant AI-powered traffic sign recognition
✅ **View Confidence**: See how confident the model is in its prediction

## 📋 App Features

| Feature | Details |
|---------|---------|
| **Camera Integration** | Capture photos on the fly |
| **Gallery Support** | Select existing images |
| **Real-time Processing** | Fast image classification |
| **Confidence Scores** | See prediction accuracy |
| **Clean UI** | User-friendly interface |

## 🔧 Key Files

- **`lib/main.dart`** - Main app UI and logic
- **`lib/tflite_service.dart`** - TensorFlow Lite model handling
- **`assets/best_float32.tflite`** - Your trained model
- **`assets/_classes.txt`** - Traffic sign labels

## 📚 Recognizes These Signs (28 total)

- Speed limit signs (20 km/h, 30 km/h, 50 mph)
- Direction signs (Left, Right, Straight, Left+Right)
- Warning signs (Children, Curves, Uneven road, etc.)
- Regulatory signs (Stop, No entry, No overtaking)
- And more...

## ⚙️ System Requirements

- **Flutter**: 3.9.2+
- **Android**: 6.0+ (API 24+)
- **iOS**: 12.0+
- **Storage**: ~50MB
- **RAM**: 2GB+

## 🐛 Troubleshooting

### App won't run?
```bash
flutter clean
flutter pub get
flutter run
```

### Camera permission error?
- Grant camera permissions in device settings
- Reinstall the app

### Model not found?
- Verify files exist in `assets/` folder:
  - `best_float32.tflite`
  - `_classes.txt`
- Check `pubspec.yaml` asset configuration

## 📞 Need Help?

1. **Check docs**: See `SETUP.md` and `PLATFORM_CONFIG.md`
2. **Flutter docs**: https://flutter.dev
3. **TFLite reference**: https://tensorflow.org/lite

## 🎯 Next Steps

### To Deploy:
- **Android**: `flutter build apk --release`
- **iOS**: `flutter build ipa --release`

### To Improve Model:
- Collect more training data
- Retrain your TensorFlow model
- Replace `best_float32.tflite`

### To Customize:
- Edit colors in `main.dart` theme
- Add more image preprocessing
- Implement real-time camera stream

---

**Ready to recognize traffic signs? Run `flutter run` now!** 🎉
