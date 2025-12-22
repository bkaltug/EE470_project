import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: const TrafficSignApp(), debugShowCheckedModeBanner: false, theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent)),));
}

class TrafficSignApp extends StatefulWidget {
  const TrafficSignApp({super.key});

  @override
  State<TrafficSignApp> createState() => _TrafficSignAppState();
}

class _TrafficSignAppState extends State<TrafficSignApp> {
  File? _image;
  String _result = "Select an image to analyze";
  final picker = ImagePicker();

  // REPLACE THIS WITH YOUR COMPUTER'S IP ADDRESS
  // If using Android Emulator, use '10.0.2.2'
  // If using a physical phone, use '192.168.1.XX' (check Step 2) 
  final String serverUrl = 'http://10.8.58.14:5000/predict';

  Future getImage(ImageSource source) async {
      final pickedFile = await picker.pickImage(
        source: source,
        // Add these lines to resize the image automatically
        maxWidth: 600,   
        maxHeight: 600,
        imageQuality: 80, // Reduces file size (compression)
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _result = "Analyzing...";
        });
        uploadImage(_image!);
      }
    }

  Future<void> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      
      // Add the image file to the request
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          _result = "Sign: ${jsonResponse['label']}\nConf: ${jsonResponse['confidence']}";
        });
      } else {
        setState(() {
          _result = "Server Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _result = "Connection Error. Check IP & Server.\nError: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TS Vision'), centerTitle: true,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text('No image selected.')
                : Image.file(_image!, height: 400),
            const SizedBox(height: 20),
            Text(_result, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 50),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon( 
                  style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(200,60))),
                  onPressed: () => getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 20,),
                  label: const Text('Camera', style: TextStyle(fontSize: 20),),
                ),
                const SizedBox(width: 10, height: 20,),
                ElevatedButton.icon(
                  style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(200,60))),
                  onPressed: () => getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo, size: 20,),
                  label: const Text('Gallery',style: TextStyle(fontSize: 20)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}