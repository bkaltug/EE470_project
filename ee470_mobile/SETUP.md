# Traffic Sign Recognizer Mobile App

A Flutter mobile application that uses TensorFlow Lite to recognize traffic signs from images captured by the device camera or selected from the gallery.

## Features

- 📸 **Camera Integration**: Take photos directly from your device camera
- 🖼️ **Gallery Support**: Pick existing images from your device gallery
- 🧠 **AI Classification**: Uses your trained TensorFlow Lite model to classify traffic signs
- 📊 **Confidence Display**: Shows the confidence level of predictions
- 🎨 **User-Friendly UI**: Clean and intuitive interface

## Project Structure

```
lib/
├── main.dart              # Main app entry point and UI
└── tflite_service.dart    # TensorFlow Lite model handling

assets/
├── best_float32.tflite    # Trained traffic sign recognition model
└── _classes.txt           # Class labels for traffic signs
```

## Model Details

The app uses a pre-trained TensorFlow Lite model (`best_float32.tflite`) that:
- Recognizes 28 different traffic sign classes
- Expects input images of 224x224 pixels
- Outputs confidence scores for each class
- Provides float32 precision predictions

## Supported Traffic Signs

The model can recognize the following traffic signs:
- Road narrows on right
- 50 mph speed limit
- Attention Please
- Beware of children
- Cycle route ahead warning
- Dangerous left curve ahead
- Dangerous right curve ahead
- End of all speed and passing limits
- Give way
- Go straight or turn right
- Go straight or turn left
- Keep-left
- Keep-right
- Left zig zag traffic
- No entry
- No over-taking
- Overtaking by trucks prohibited
- Pedestrian crossing
- Round-about
- Slippery road ahead
- Speed limit 20 kmph
- Speed limit 30 kmph
- Stop sign
- Straight ahead only
- Traffic signal
- Truck traffic prohibited
- Turn left ahead
- Turn right ahead
- Uneven road

## Installation & Setup

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Android Studio or Xcode (for device/emulator)
- A device or emulator for testing

### Dependencies

The project includes the following key dependencies:
- `image_picker: ^1.2.0` - For camera and gallery access
- `tflite_flutter: ^0.12.1` - For TensorFlow Lite inference
- `image: ^4.5.4` - For image processing

### Build Instructions

1. **Get Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app on Android**:
   ```bash
   flutter run
   ```

3. **Run the app on iOS**:
   ```bash
   flutter run
   ```

4. **Build for release**:
   - **Android**:
     ```bash
     flutter build apk --release
     ```
   - **iOS**:
     ```bash
     flutter build ios --release
     ```

## How to Use

1. **Launch the App**: Open the Traffic Sign Recognizer app on your device
2. **Select Image Source**:
   - Tap "Take Photo" to capture a new image with your camera
   - Tap "Pick from Gallery" to select an existing image
3. **Wait for Processing**: The app will automatically process the image
4. **View Result**: The recognized traffic sign label and confidence percentage will be displayed

## Technical Details

### Image Processing Pipeline
1. Image is loaded and decoded
2. Image is resized to 224x224 pixels (model input size)
3. Pixel values are normalized to [0, 1] range
4. Image data is converted to float32 format

### Model Inference
1. Processed image is fed to the TensorFlow Lite interpreter
2. Model outputs raw confidence scores for each class
3. Softmax function is applied to convert scores to probabilities
4. Class with highest probability is selected as prediction

### Result Display
- **Label**: The recognized traffic sign name
- **Confidence**: Probability score as a percentage (0-100%)

## Permissions

The app requires the following permissions:
- **Camera**: To capture photos
- **Storage/Photo Library**: To access images from device gallery

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to recognize traffic signs</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images for sign recognition</string>
```

## Troubleshooting

### Model Not Loading
- Verify that `best_float32.tflite` exists in `assets/` folder
- Check that `pubspec.yaml` has the assets configured correctly
- Run `flutter clean` and `flutter pub get`

### Image Processing Errors
- Ensure image format is supported (JPG, PNG)
- Try with a different image if one fails
- Check device memory availability

### TensorFlow Lite Issues
- Update `tflite_flutter` package: `flutter pub upgrade tflite_flutter`
- Check compatibility with your target platform
- Review native build logs for detailed errors

## Performance Notes

- First inference may be slower (model loading and warm-up)
- Subsequent predictions are faster
- Image processing takes ~100-500ms depending on device
- Model inference typically completes in <1 second

## Future Enhancements

- Real-time camera stream processing
- Batch processing multiple images
- Model accuracy metrics display
- Support for different model inputs
- Image augmentation options
- Result history

## License

This project uses a trained TensorFlow Lite model for traffic sign recognition.

## Support

For issues or questions, check:
- Flutter documentation: https://flutter.dev
- TensorFlow Lite documentation: https://tensorflow.org/lite
- TFLite Flutter plugin: https://pub.dev/packages/tflite_flutter
