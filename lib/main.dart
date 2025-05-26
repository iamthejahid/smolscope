import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Interaction',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CameraScreen(cameras: cameras),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initCamera;
  Timer? _timer;

  final String _baseUrl = 'http://192.168.1.106:8080';
  int _intervalMs = 500;
  bool _isProcessing = false;
  bool _isSending = false;

  String _responseText = "Server response will appear here...";
  final TextEditingController _instructionController = TextEditingController(
    text: "What do you see?",
  );

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.cameras.first,
      ResolutionPreset.medium,
    );
    _initCamera = _cameraController.initialize();
  }

  @override
  void dispose() {
    _stopProcessing();
    _cameraController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<String?> _captureImageBase64() async {
    try {
      await _initCamera;
      final file = await _cameraController.takePicture();
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e, stackTrace) {
      debugPrint("Capture failed: $e");
      debugPrintStack(stackTrace: stackTrace);
      _showSnackBar("Failed to capture image.");
      return null;
    }
  }

  Future<String> _sendToServer(String instruction, String imageBase64) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'max_tokens': 100,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': instruction},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'},
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? 'No content';
      } else {
        return 'Server error: ${response.statusCode}';
      }
    } catch (e, stackTrace) {
      debugPrint("Request failed: $e");
      debugPrintStack(stackTrace: stackTrace);
      return 'Error sending request: $e';
    }
  }

  Future<void> _sendData() async {
    if (!_isProcessing || _isSending) return;
    _isSending = true;

    final instruction = _instructionController.text.trim();
    final imageBase64 = await _captureImageBase64();

    if (imageBase64 == null) {
      setState(() => _responseText = "Failed to capture image.");
      _isSending = false;
      return;
    }

    final result = await _sendToServer(instruction, imageBase64);
    setState(() => _responseText = result);

    _isSending = false;
  }

  void _startProcessing() {
    setState(() => _isProcessing = true);
    _sendData();
    _timer = Timer.periodic(
      Duration(milliseconds: _intervalMs),
      (_) => _sendData(),
    );
  }

  void _stopProcessing() {
    _timer?.cancel();
    setState(() => _isProcessing = false);
  }

  void _toggleProcessing() {
    _isProcessing ? _stopProcessing() : _startProcessing();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Camera Interaction")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            FutureBuilder(
              future: _initCamera,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SizedBox(
                    height: 450,
                    child: CameraPreview(_cameraController),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildResponseCard()),
            _buildInstructionInput(),
            const SizedBox(height: 10),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Text(_responseText, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildInstructionInput() {
    return TextField(
      controller: _instructionController,
      decoration: const InputDecoration(
        labelText: 'Instruction',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        const Text("Interval:"),
        const SizedBox(width: 10),
        DropdownButton<int>(
          value: _intervalMs,
          items: const [
            DropdownMenuItem(value: 100, child: Text("100ms")),
            DropdownMenuItem(value: 250, child: Text("250ms")),
            DropdownMenuItem(value: 500, child: Text("500ms")),
            DropdownMenuItem(value: 1000, child: Text("1s")),
            DropdownMenuItem(value: 2000, child: Text("2s")),
          ],
          onChanged:
              _isProcessing
                  ? null
                  : (value) {
                    if (value != null) setState(() => _intervalMs = value);
                  },
        ),
        const Spacer(),
        ElevatedButton.icon(
          icon: Icon(_isProcessing ? Icons.stop : Icons.play_arrow),
          label: Text(_isProcessing ? "Stop" : "Start"),
          onPressed: _toggleProcessing,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isProcessing ? Colors.red : Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
