// lib/services/ai_service.dart
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ai_forecast_result_model.dart';

class AiService {
  AiService()
      : _model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-3.5-flash',
        );

  final GenerativeModel _model;

  Future<AiForecastResultModel> generateForecast({
    required double monthlyBudget,
    required double currentSpend,
    required Map<String, double> categoryTotals,
    required List<Map<String, dynamic>> recentExpenses,
  }) async {
    final prompt = '''
You are an AI finance assistant for a family expense app.

Your task:
1. Predict the total month-end family spending.
2. Explain the forecast in very simple words.
3. Give one short warning.

Return ONLY valid JSON.
Do not write markdown.
Do not use code fences.
Do not add extra explanation outside JSON.

Required JSON format:
{
  "forecastAmount": 0,
  "insight": "short simple sentence",
  "warning": "short simple sentence"
}

Instructions:
- forecastAmount must be a realistic estimate based on the current spending trend
- do not return random values
- if current spending is low, keep forecast close to the current trend
- if current spending is high, reflect that in the forecast
- insight must clearly explain the main reason for the forecast
- warning must clearly tell whether the family may exceed the budget or stay within it
- use very simple English
- keep insight and warning short
- if there are no expenses yet, forecastAmount should be 0
- if there are no expenses yet, insight should say no expenses recorded yet
- if no budget is set, warning should say that no monthly budget is set

Data:
Monthly budget: $monthlyBudget
Current monthly spend: $currentSpend
Category totals: ${jsonEncode(categoryTotals)}
Recent expenses: ${jsonEncode(recentExpenses)}

Examples of good output:
{
  "forecastAmount": 52000,
  "insight": "Groceries are the main reason for high spending this month.",
  "warning": "At this pace, your family may exceed the monthly budget."
}

{
  "forecastAmount": 18000,
  "insight": "Spending is currently moderate and spread across a few categories.",
  "warning": "Your family is still within a safe budget range."
}
''';

    try {
      final response = await _model.generateContent([
        Content.text(prompt),
      ]);

      final rawText = response.text?.trim() ?? '';
      final cleaned = _cleanJson(rawText);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      return AiForecastResultModel.fromJson(decoded);
    } catch (_) {
      return AiForecastResultModel.fallback(
        currentSpend: currentSpend,
      );
    }
  }

  String _cleanJson(String text) {
    var cleaned = text.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceFirst('```json', '').trim();
    }

    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst('```', '').trim();
    }

    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3).trim();
    }

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    return cleaned;
  }
}