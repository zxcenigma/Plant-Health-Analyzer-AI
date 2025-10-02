import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiClient {
  final String baseUrl; // напр. http://192.168.0.10:8000
  ApiClient(this.baseUrl);

  Future<PredictResponse> predict(File imageFile,
      {double conf = 0.25, int imgsz = 640}) async {
    final uri = Uri.parse('$baseUrl/predict?conf=$conf&imgsz=$imgsz');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return PredictResponse.fromJson(jsonDecode(body));
    } else {
      throw Exception('API error ${streamed.statusCode}: $body');
    }
  }
}