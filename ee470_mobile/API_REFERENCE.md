# API Reference & Developer Guide

## TFLiteService Class

The `TFLiteService` class handles all TensorFlow Lite model operations.

### Methods

#### `Future<void> initialize()`
Initializes the TensorFlow Lite model and loads class labels.

**Usage:**
```dart
_tfLiteService = TFLiteService();
await _tfLiteService.initialize();
```

**Error Handling:**
```dart
try {
  await _tfLiteService.initialize();
} catch (e) {
  print('Failed to initialize: $e');
}
```

---

#### `Future<Map<String, dynamic>> classifyImage(File imageFile)`
Classifies an image using the TensorFlow Lite model.

**Parameters:**
- `imageFile` (File): Image file to classify

**Returns:**
```dart
{
  'label': String,      // Recognized traffic sign name
  'confidence': double  // Confidence score (0.0 - 1.0)
}
```

**Usage:**
```dart
final result = await _tfLiteService.classifyImage(imageFile);
String signName = result['label'];
double confidence = result['confidence'];
print('Sign: $signName (${(confidence * 100).toStringAsFixed(2)}%)');
```

**Example Output:**
```dart
{
  'label': 'Stop_Sign',
  'confidence': 0.9876
}
```

---

#### `void dispose()`
Releases resources used by the TensorFlow Lite interpreter.

**Usage:**
```dart
@override
void dispose() {
  _tfLiteService.dispose();
  super.dispose();
}
```

---

## Main App Class

### TrafficSignRecognizer Widget

Main stateful widget for the app UI.

### State Variables

```dart
File? _selectedImage;        // Currently selected image
String? _prediction;          // Recognized sign label
double? _confidence;          // Confidence score
bool _isLoading;              // Loading state
late TFLiteService _tfLiteService;  // Model service
```

---

### Methods

#### `void _initializeTFLite()`
Initializes the TFLite service on widget creation.

```dart
@override
void initState() {
  super.initState();
  _initializeTFLite();
}

void _initializeTFLite() async {
  _tfLiteService = TFLiteService();
  await _tfLiteService.initialize();
}
```

---

#### `Future<void> _pickImage(ImageSource source)`
Opens image picker to select an image.

**Parameters:**
- `source` (ImageSource): `ImageSource.camera` or `ImageSource.gallery`

**Usage:**
```dart
// Take photo
_pickImage(ImageSource.camera);

// Pick from gallery
_pickImage(ImageSource.gallery);
```

**Behavior:**
1. Opens image picker
2. Returns selected image
3. Automatically calls `_classifyImage()`

---

#### `Future<void> _classifyImage()`
Processes selected image through the model.

**Behavior:**
1. Sets `_isLoading` to true
2. Calls `TFLiteService.classifyImage()`
3. Updates `_prediction` and `_confidence`
4. Sets `_isLoading` to false
5. Shows errors in SnackBar if they occur

**State Updates:**
```dart
setState(() {
  _prediction = result['label'];
  _confidence = result['confidence'];
});
```

---

## Image Processing Pipeline

### Image Resize
```dart
image = img.copyResize(image, width: 224, height: 224);
```
- Input: Any size image
- Output: 224×224 pixels

### Normalization
```dart
double r = pixel.r.toDouble() / 255.0;
double g = pixel.g.toDouble() / 255.0;
double b = pixel.b.toDouble() / 255.0;
```
- Converts pixel values from [0-255] to [0-1]

### Tensor Conversion
```dart
final inputData = _imageToByteListFloat32(image);
```
- Converts image to flattened float32 array
- Format: [R1,G1,B1,R2,G2,B2,...,R224²,G224²,B224²]

---

## Softmax Function

Used to convert raw model outputs to probabilities.

```dart
List<double> _softmax(List<double> input) {
  final List<double> output = [];
  final double maxInput = input.reduce((a, b) => a > b ? a : b);
  
  double sum = 0.0;
  for (double val in input) {
    sum += pow(2.718281828, val - maxInput).toDouble();
  }
  
  for (double val in input) {
    output.add(pow(2.718281828, val - maxInput).toDouble() / sum);
  }
  
  return output;
}
```

**Formula:**
```
softmax(x_i) = e^(x_i - max(x)) / Σ(e^(x_j - max(x)))
```

---

## Model Specifications

### Input Tensor
- **Shape**: [1, 224, 224, 3]
- **Type**: float32
- **Range**: [0.0, 1.0] (normalized RGB)

### Output Tensor
- **Shape**: [1, 28]
- **Type**: float32
- **Values**: Raw logits or probabilities

### Inference Parameters
- **Input size**: 224×224 pixels
- **Number of classes**: 28 traffic signs
- **Expected processing time**: 100-500ms

---

## Error Handling Examples

### Model Initialization Error
```dart
try {
  await _tfLiteService.initialize();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Model failed to load: $e')),
  );
}
```

### Image Classification Error
```dart
try {
  final result = await _tfLiteService.classifyImage(_selectedImage!);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Classification failed: $e')),
  );
}
```

### Image Picker Error
```dart
try {
  final XFile? pickedFile = await picker.pickImage(source: source);
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error picking image: $e')),
  );
}
```

---

## Customization Guide

### Change Model Input Size
**Current:** 224×224

**To change to 256×256:**
1. Edit `tflite_service.dart`:
   ```dart
   // Line ~35
   image = img.copyResize(image, width: 256, height: 256);
   ```

### Change Number of Classes
**Current:** 28 classes

**To change:**
1. Update `_classes.txt` with new class labels
2. Model output shape will automatically adjust

### Add Image Preprocessing
**Example - Add brightness adjustment:**
```dart
// In _imageToByteListFloat32() before normalization
double brightness = 1.2;
double r = (pixel.r.toDouble() * brightness).clamp(0, 255) / 255.0;
double g = (pixel.g.toDouble() * brightness).clamp(0, 255) / 255.0;
double b = (pixel.b.toDouble() * brightness).clamp(0, 255) / 255.0;
```

### Change UI Theme
**Current:** Blue primary color

**To change to green:**
```dart
// In main.dart, line ~18
colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
```

### Modify Result Display
**To show top 5 predictions:**
```dart
// Modify output extraction in classifyImage()
final topIndices = output
    .asMap()
    .entries
    .toList()
    ..sort((a, b) => b.value.compareTo(a.value))
    .take(5)
    .toList();

List<Map<String, dynamic>> topResults = [];
for (var entry in topIndices) {
  topResults.add({
    'label': _labels![entry.key],
    'confidence': _softmax(output)[entry.key]
  });
}
```

---

## Performance Tips

### Optimize Inference Speed
1. **Reduce image size**: Smaller images process faster
2. **Batch processing**: Process multiple images sequentially
3. **Model optimization**: Use quantized models

### Memory Management
1. **Dispose properly**: Always call `dispose()` on exit
2. **Clear cache**: Use `flutter clean` if memory issues occur
3. **Monitor logs**: Check `adb logcat` for memory leaks

### Battery Efficiency
1. **Batch operations**: Fewer model invocations
2. **Optimize preprocessing**: Minimize pixel operations
3. **Smart caching**: Reuse processed images

---

## Testing Guide

### Unit Testing
```dart
void main() {
  group('TFLiteService', () {
    late TFLiteService service;

    setUpAll(() async {
      service = TFLiteService();
      await service.initialize();
    });

    test('classifyImage returns valid result', () async {
      // Test implementation
    });

    tearDownAll(() {
      service.dispose();
    });
  });
}
```

### Integration Testing
```dart
testWidgets('App classifies image correctly', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Tap image picker
  await tester.tap(find.byIcon(Icons.camera_alt));
  await tester.pumpAndSettle();
  
  // Verify results displayed
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

---

## Dependencies Reference

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | Core framework |
| image_picker | ^1.2.0 | Camera & gallery |
| tflite_flutter | ^0.12.1 | ML inference |
| image | ^4.5.4 | Image processing |

---

## Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v
```

### Check Native Logs
**Android:**
```bash
adb logcat | grep -i tflite
```

**iOS:**
```bash
log stream --predicate 'eventMessage contains[cd] "tflite"'
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Model not loading | Check asset path in pubspec.yaml |
| Out of memory | Reduce image size or clear cache |
| Permission denied | Check AndroidManifest.xml / Info.plist |
| Model timeout | Increase timeout or optimize preprocessing |

---

## Version Information

- **Flutter**: 3.9.2+
- **Dart**: 3.3.0+
- **Android SDK**: 24+
- **iOS**: 12.0+

---

## Support Resources

- **Flutter Docs**: https://flutter.dev/docs
- **TFLite Docs**: https://tensorflow.org/lite/guide
- **TFLite Plugin**: https://pub.dev/packages/tflite_flutter
- **Image Package**: https://pub.dev/packages/image

