import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forecast_point.dart';
import '../config/api_config.dart';

class ForecastApi {
  static const String baseUrl = ApiConfig.pythonAiUrl;

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
