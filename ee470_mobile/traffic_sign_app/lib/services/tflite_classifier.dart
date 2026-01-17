import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class PredictionResult {
  final int classId;
  final String label;
  final double confidence;

  PredictionResult({
    required this.classId,
    required this.label,
    required this.confidence,
  });
}

class TFLiteClassifier {
  static const String modelPath = 'assets/traffic_sign_model.tflite';
  static const String labelsPath = 'assets/labels.txt';
  static const int inputSize = 30;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  /// Singleton pattern
  static final TFLiteClassifier _instance = TFLiteClassifier._internal();
  factory TFLiteClassifier() => _instance;
  TFLiteClassifier._internal();

  bool get isInitialized => _isInitialized;

  /// Initialize the TFLite model and load labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('TFLite model loaded successfully');

      // Print model input/output shapes for debugging
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('Input shape: $inputShape');
      print('Output shape: $outputShape');

      // Load labels
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData.split('\n').where((l) => l.isNotEmpty).toList();
      print('Loaded ${_labels.length} labels');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing TFLite classifier: $e');
      rethrow;
    }
  }

  /// Predict traffic sign from image file
  Future<PredictionResult> predict(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Read and preprocess the image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Fix orientation using EXIF data if available
      final orientedImage = img.bakeOrientation(image);

      // Resize to model input size
      final resizedImage = img.copyResize(
        orientedImage,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Prepare input tensor - shape: [1, 30, 30, 3] 
      // Normalize to [0, 1] range (same as PyTorch ToTensor())
      final input = List.generate(
        1, // batch size
        (_) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r / 255.0, // Red channel
                pixel.g / 255.0, // Green channel
                pixel.b / 255.0, // Blue channel
              ];
            },
          ),
        ),
      );

      // Prepare output tensor - shape: [1, 29]
      final output = List.generate(1, (_) => List.filled(_labels.length, 0.0));

      // Run inference
      _interpreter!.run(input, output);

      // Apply softmax to get probabilities
      final logits = output[0];
      final probabilities = _softmax(logits);

      // Find the predicted class
      int predictedClass = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          predictedClass = i;
        }
      }

      return PredictionResult(
        classId: predictedClass,
        label: _labels[predictedClass],
        confidence: maxProb,
      );
    } catch (e) {
      print('Error during prediction: $e');
      rethrow;
    }
  }

  /// Apply softmax to logits
  List<double> _softmax(List<double> logits) {
    // Find max for numerical stability
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);

    // Compute exp(logit - max)
    final expValues = logits.map((l) => math.exp(l - maxLogit)).toList();

    // Sum of all exp values
    final sumExp = expValues.reduce((a, b) => a + b);

    // Normalize
    return expValues.map((e) => e / sumExp).toList();
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
