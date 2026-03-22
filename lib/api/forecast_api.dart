import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_point.dart';

class ForecastApi {
  // IMPORTANT:
  // Android emulator -> use 10.0.2.2
  // Physical phone -> use your PC IP (e.g. http://192.168.1.5:8000)
  // iOS simulator -> use http://127.0.0.1:8000
  static const String baseUrl = "http://127.0.0.1:8000";

  static Future<List<ForecastPoint>> fetchForecast({
    required String userId,
    int horizon = 30,
  }) async {
    final uri = Uri.parse(
      "$baseUrl/predict-spending?user_id=$userId&horizon=$horizon",
    );
    final res = await http.get(uri);

    if (res.statusCode != 200) {
      throw Exception("Forecast API error: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (decoded["forecast"] as List).cast<Map<String, dynamic>>();
    return list.map((e) => ForecastPoint.fromJson(e)).toList();
  }
}
