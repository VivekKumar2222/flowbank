class ForecastPoint {
  final DateTime ds;
  final double yhat;
  final double yhatLower;
  final double yhatUpper;

  ForecastPoint({
    required this.ds,
    required this.yhat,
    required this.yhatLower,
    required this.yhatUpper,
  });

  factory ForecastPoint.fromJson(Map<String, dynamic> json) {
    return ForecastPoint(
      ds: DateTime.parse(json['ds']),
      yhat: (json['yhat'] as num).toDouble(),
      yhatLower: (json['yhat_lower'] as num).toDouble(),
      yhatUpper: (json['yhat_upper'] as num).toDouble(),
    );
  }
}
