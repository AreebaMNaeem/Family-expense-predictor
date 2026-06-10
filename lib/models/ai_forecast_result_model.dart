// lib/models/ai_forecast_result_model.dart
class AiForecastResultModel {
  const AiForecastResultModel({
    required this.forecastAmount,
    required this.insight,
    required this.warning,
  });

  final double forecastAmount;
  final String insight;
  final String warning;

  factory AiForecastResultModel.fromJson(Map<String, dynamic> json) {
    return AiForecastResultModel(
      forecastAmount: (json['forecastAmount'] as num?)?.toDouble() ?? 0,
      insight: (json['insight'] as String?)?.trim() ?? '',
      warning: (json['warning'] as String?)?.trim() ?? '',
    );
  }

  factory AiForecastResultModel.fallback({
    required double currentSpend,
  }) {
    return AiForecastResultModel(
      forecastAmount: currentSpend,
      insight: 'AI insight is temporarily unavailable.',
      warning: 'Unable to generate a forecast right now.',
    );
  }
}