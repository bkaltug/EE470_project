import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class PredictionResult {
  final int classId;
  final String label;
  final double confidence;

  PredictionResult({
    required this.classId,
    required this.label,
    required this.confidence,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      classId: json['class_id'] as int,
      label: json['label'] as String,
      confidence: double.parse(json['confidence'].toString()),
    );
  }
}

class ApiService {
  // Change this to your computer's IP address when running the Flask server
  // Use 10.0.2.2 for Android emulator (localhost equivalent)
  // Use your actual local IP (e.g., 192.168.x.x) for physical devices
  static const String baseUrl = 'http://192.168.1.100:5000';

  /// Updates the base URL for the API
  static String _currentBaseUrl = baseUrl;

  static void updateBaseUrl(String newUrl) {
    _currentBaseUrl = newUrl;
  }

  static String get currentBaseUrl => _currentBaseUrl;

  /// Sends an image file to the prediction API and returns the result
  static Future<PredictionResult> predictTrafficSign(File imageFile) async {
    try {
      final uri = Uri.parse('$_currentBaseUrl/predict');

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Please check if the server is running.',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PredictionResult.fromJson(jsonData);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to predict traffic sign');
      }
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Please ensure:\n'
        '1. The Flask server is running\n'
        '2. The IP address is correct\n'
        '3. Both devices are on the same network',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
