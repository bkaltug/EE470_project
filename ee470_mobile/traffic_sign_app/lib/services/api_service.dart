import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_settings.dart';
import 'tflite_classifier.dart' show PredictionResult;

export 'tflite_classifier.dart' show PredictionResult;

class ApiService {
  static final AppSettings _settings = AppSettings();

  /// Sends an image file to the prediction API and returns the result
  static Future<PredictionResult> predictTrafficSign(File imageFile) async {
    try {
      final uri = Uri.parse('${_settings.apiBaseUrl}/predict');

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
        return PredictionResult(
          classId: jsonData['class_id'] as int,
          label: jsonData['label'] as String,
          confidence: double.parse(jsonData['confidence'].toString()),
        );
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
