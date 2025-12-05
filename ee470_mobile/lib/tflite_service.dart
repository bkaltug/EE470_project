import 'dart:io';
import 'dart:math' show pow;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> initialize() async {
    try {
      print('Initializing TFLite model...');
      _interpreter = await Interpreter.fromAsset('assets/best_float32.tflite');
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      
      print('✓ Model loaded');
      print('  Input shape: ${inputTensor.shape}');
      print('  Output shape: ${outputTensor.shape}');
      
      final labelsData = await rootBundle.loadString('assets/_classes.txt');
      _labels = labelsData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();
      
      print('✓ Loaded ${_labels!.length} classes');
      print('  First class: "${_labels![0]}"');
      print('  Last class: "${_labels![_labels!.length - 1]}"');
      
      // Validate output shape matches number of classes
      final numOutputClasses = outputTensor.shape.last;
      if (numOutputClasses != _labels!.length) {
        print('⚠️ Warning: Model outputs $numOutputClasses classes but file has ${_labels!.length}');
      }
    } catch (e) {
      print('✗ Init error: $e');
      throw Exception('Failed to initialize TFLite: $e');
    }
  }

  Future<Map<String, dynamic>> classifyImage(File imageFile) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('Model not initialized');
    }

    try {
      print('\n=== Classifying ===');
      
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) throw Exception('Failed to decode image');

      print('Image: ${image.width}x${image.height}');
      image = img.copyResize(image, width: 224, height: 224);
      print('Resized to 224x224');

      final inputTensor = _interpreter!.getInputTensor(0);
      final inputShape = inputTensor.shape;
      print('Input shape: $inputShape');

      // Create 4D tensor strictly typed
      final input = List<List<List<List<double>>>>.generate(
        1,
        (_) => List<List<List<double>>>.generate(
          224,
          (y) => List<List<double>>.generate(
            224,
            (x) {
              final p = image!.getPixelSafe(x, y);
              return [
                p.r.toDouble() / 255.0,
                p.g.toDouble() / 255.0,
                p.b.toDouble() / 255.0,
              ];
            },
          ),
        ),
      );

      final outputTensor = _interpreter!.getOutputTensor(0);
      final output = List<double>.filled(outputTensor.shape.last, 0.0);

      print('Running inference...');
      print('  Output buffer size: ${output.length}');
      print('  Classes available: ${_labels!.length}');
      _interpreter!.run(input, output);
      print('✓ Done');

      int topIdx = 0;
      double topVal = output[0];
      for (int i = 1; i < output.length; i++) {
        if (output[i] > topVal) {
          topVal = output[i];
          topIdx = i;
        }
      }

      final probs = _softmax(output);
      final label = topIdx < _labels!.length
          ? _labels![topIdx].trim()
          : 'Unknown';
      final confidence = probs[topIdx];

      print('Result: $label (${(confidence * 100).toStringAsFixed(2)}%)');
      print('===\n');

      return {'label': label, 'confidence': confidence};
    } catch (e) {
      print('✗ Error: $e');
      rethrow;
    }
  }

  List<double> _softmax(List<double> input) {
    final maxVal = input.reduce((a, b) => a > b ? a : b);
    final exps = input.map((v) => pow(2.718281828, v - maxVal).toDouble()).toList();
    final sumExp = exps.fold<double>(0.0, (s, v) => s + v);
    return exps.map((v) => v / sumExp).toList();
  }

  void dispose() {
    _interpreter?.close();
  }
}
