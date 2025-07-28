import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request camera and flash permission
  await Permission.camera.request();
  await Permission.manageExternalStorage.request(); // Optional for future
  await Permission.microphone.request(); // just in case

  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HeartRateMonitor(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HeartRateMonitor extends StatefulWidget {
  @override
  _HeartRateMonitorState createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  late CameraController controller;
  List<int> redValues = [];
  int bpm = 0;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    controller = CameraController(
      cameras![0], // Use rear camera
      ResolutionPreset.low,
      enableAudio: false,
    );
    await controller.initialize();
    await controller.setFlashMode(FlashMode.torch);
    await controller.startImageStream(processImage);
    setState(() {});
  }

  void processImage(CameraImage image) async {
    if (isProcessing) return;
    isProcessing = true;

    final bytes = image.planes[0].bytes;
    int total = 0;
    for (int i = 0; i < bytes.length; i += 3) {
      total += bytes[i];
    }
    int avgRed = total ~/ (bytes.length ~/ 3);
    redValues.add(avgRed);

    if (redValues.length > 100) {
      redValues.removeAt(0);
      int peaks = 0;
      for (int i = 1; i < redValues.length - 1; i++) {
        if (redValues[i] > redValues[i - 1] && redValues[i] > redValues[i + 1]) {
          peaks++;
        }
      }
      bpm = peaks * 6;
      setState(() {});
    }

    isProcessing = false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F7F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2FEFA), Color(0xFF0ED2F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: const Text(
            "HeartEase",
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Place your finger gently on the camera + flash",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.favorite, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    "$bpm BPM",
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 250,
                child: CameraPreview(controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
