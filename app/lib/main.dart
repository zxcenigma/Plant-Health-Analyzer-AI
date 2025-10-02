import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api_client.dart';
import 'models.dart';
import 'overlay_painter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Health Analyzer',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  final _api = ApiClient('http://127.0.0.1:8888'); // Android эмулятор -> твой FastAPI
  // Для реального устройства по Wi-Fi: http://<ip_компа>:8000

  File? _imageFile;
  PredictResponse? _resp;
  Size? _imageSize;
  bool _loading = false;
  String? _error;

  Future<void> _pickAndSend(ImageSource src) async {
    setState(() {
      _loading = true;
      _error = null;
      _resp = null;
    });
    try {
      final xfile = await _picker.pickImage(source: src, imageQuality: 95);
      if (xfile == null) {
        setState(() => _loading = false);
        return;
      }
      final file = File(xfile.path);
      final image = await decodeImageFromList(await file.readAsBytes());
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _imageFile = file;

      final r = await _api.predict(file, conf: 0.25, imgsz: 640);
      setState(() {
        _resp = r;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _imageFile;
    final resp = _resp;
    final imgSize = _imageSize;

    return Scaffold(
      appBar: AppBar(title: const Text('Plant Health Analyzer')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _pickAndSend(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Галерея'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickAndSend(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Камера'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            if (img != null && imgSize != null)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return FittedBox(
                      fit: BoxFit.contain,
                      child: Stack(
                        children: [
                          Image.file(img),
                          if (resp != null)
                            CustomPaint(
                              painter: DetectionPainter(
                                objects: resp.objects,
                                imageSize: imgSize,
                              ),
                              child: SizedBox(
                                width: imgSize.width,
                                height: imgSize.height,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(child: Text('Выбери фото для анализа')),
              ),
            const SizedBox(height: 8),
            if (resp != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: resp.summary.entries
                    .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}