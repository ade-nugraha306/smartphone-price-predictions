import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8000";
    }
    return "http://127.0.0.1:8000";
  }

  static Future<Map<String, dynamic>> predict(
      Map<String, dynamic> spec) async {
    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(spec),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Backend error ${response.statusCode}: ${response.body}",
      );
    }
  }

  static Future<Map<String, dynamic>> predictAndRecommend(
      Map<String, dynamic> spec) async {
    final res = await http.post(
      Uri.parse("$baseUrl/predict-and-recommend"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(spec),
    );

    if (res.statusCode != 200) {
      throw Exception(
        "Backend error ${res.statusCode}: ${res.body}",
      );
    }

    return jsonDecode(res.body);
  }
}
