import 'package:flutter/foundation.dart';

enum InferenceMode {
  tflite,
  api,
}

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  InferenceMode _inferenceMode = InferenceMode.tflite;
  String _apiBaseUrl = 'http://192.168.1.96:5000';

  InferenceMode get inferenceMode => _inferenceMode;
  String get apiBaseUrl => _apiBaseUrl;

  bool get useTFLite => _inferenceMode == InferenceMode.tflite;
  bool get useApi => _inferenceMode == InferenceMode.api;

  void setInferenceMode(InferenceMode mode) {
    _inferenceMode = mode;
    notifyListeners();
  }

  void setApiBaseUrl(String url) {
    // Remove trailing slash if present
    _apiBaseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    notifyListeners();
  }
}
