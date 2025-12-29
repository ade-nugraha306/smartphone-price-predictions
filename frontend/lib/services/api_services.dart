import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

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
      throw Exception("Gagal mengambil prediksi");
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
      throw Exception("Failed to fetch prediction");
    }

    return jsonDecode(res.body);
  }
}
