// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:google_generative_ai/google_generative_ai.dart';
//
// class FoodAnalysis {
//   final String label;         // "healthy" | "not_healthy" | "uncertain"
//   final int score;            // 0..10
//   final String action;        // "eat" | "limit" | "avoid"
//   final String calories;
//   final List<String> reasons; // short bullets
//   final List<String> tips;    // safer swaps
//
//   FoodAnalysis({
//     required this.label,
//     required this.score,
//     required this.action,
//     required this.calories,
//     required this.reasons,
//     required this.tips,
//   });
//
//   factory FoodAnalysis.fromJson(Map<String, dynamic> j) {
//     return FoodAnalysis(
//       label: (j["label"] ?? "uncertain").toString(),
//       score: (j["score"] is int) ? j["score"] : int.tryParse("${j["score"]}") ?? 0,
//       action: (j["action"] ?? "limit").toString(),
//       calories: (j["calories"] ?? "limit" ).toString(),
//       reasons: (j["reasons"] as List?)?.map((e) => "$e").toList() ?? const [],
//       tips: (j["tips"] as List?)?.map((e) => "$e").toList() ?? const [],
//     );
//   }
// }
//
// class FoodAnalyzer {
//   final GenerativeModel _model;
//
//   FoodAnalyzer({required String apiKey})
//       : _model = GenerativeModel(
//     // Use a multimodal model (text+image). Example models are shown in Gemini docs. :contentReference[oaicite:3]{index=3}
//     model: 'gemini-2.5-flash',
//     apiKey: apiKey,
//   );
//
//   Future<FoodAnalysis> analyzeFoodImage({
//     required Uint8List bytes,
//     required String mimeType, // "image/jpeg" or "image/png"
//   }) async {
//     final prompt = '''
// You are a food label assistant. Analyze the food in the image.
//
// Return ONLY valid JSON (no markdown) with exactly:
// {
//   "label": "healthy" | "not_healthy" | "uncertain",
//   "score": 0-10,
//   "action": "eat" | "limit" | "avoid",
//   "calories":"...",
//   "reasons": ["...","...","..."],
//   "tips": ["...","..."]
// }
//
// Rules:
// - If you cannot identify the food, use label "uncertain" and explain in reasons.
// - Keep reasons short and practical.
// - Do NOT give medical diagnosis. Avoid absolute claims.
// ''';
//
//     final content = [
//       Content.multi([
//         DataPart(mimeType, bytes),
//         TextPart(prompt),
//       ])
//     ];
//
//     final resp = await _model.generateContent(content);
//     final text = (resp.text ?? "").trim();
//
//     // Robust JSON extraction: sometimes models add extra text; try to slice first {...} block.
//     final jsonStr = _extractFirstJsonObject(text);
//     final map = json.decode(jsonStr) as Map<String, dynamic>;
//     return FoodAnalysis.fromJson(map);
//   }
//
//   String _extractFirstJsonObject(String input) {
//     final start = input.indexOf('{');
//     final end = input.lastIndexOf('}');
//     if (start == -1 || end == -1 || end <= start) {
//       // fallback: force empty uncertain response
//       return json.encode({
//         "label": "uncertain",
//         "score": 0,
//         "action": "limit",
//         "calories": "limit",
//         "reasons": ["Could not parse the model response as JSON."],
//         "tips": ["Try taking a clearer photo with good lighting."]
//       });
//     }
//     return input.substring(start, end + 1);
//   }
// }
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FoodAnalysis {
  final String foodsAndDrinkOrNot;
  final String drinkOrFood; // drink or food
  final String label; // "healthy" | "not_healthy" | "uncertain"
  final double freshness;
  final int score; // 0..10
  final String action; // "eat" | "limit" | "avoid"
  final String calories; // simple text
  final List<String> reasons; // short bullets
  final List<String> tips; // safer swaps

  FoodAnalysis({
    required this.foodsAndDrinkOrNot,
    required this.drinkOrFood,
    required this.label,
    required this.freshness,
    required this.score,
    required this.action,
    required this.calories,
    required this.reasons,
    required this.tips,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> j) {
    return FoodAnalysis(
      foodsAndDrinkOrNot: (j["foods_and_drink_or_not"] ?? "food_or_drink").toString(),
      drinkOrFood: (j["drink_or_food"] ?? "food").toString(),
      label: (j["label"] ?? "uncertain").toString(),
      freshness:
          (j["freshness"] is num)
              ? (j["freshness"] as num).toDouble()
              : double.tryParse(j["freshness"]?.toString() ?? "0") ?? 0,
      score:
          (j["score"] is int) ? j["score"] : int.tryParse("${j["score"]}") ?? 0,
      action: (j["action"] ?? "limit").toString(),
      calories: (j["calories"] ?? "unknown").toString(),
      reasons: (j["reasons"] as List?)?.map((e) => "$e").toList() ?? const [],
      tips: (j["tips"] as List?)?.map((e) => "$e").toList() ?? const [],
    );
  }
}

class FoodAnalyzer {
  // Same function name, same params, same return type
  Future<FoodAnalysis> analyzeFoodImage({
    required Uint8List bytes,
    required String mimeType, // "image/jpeg" or "image/png"
  }) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("OPENROUTER_API_KEY missing in .env");
    }

    final prompt = '''
    You are a Healthy Or Now Food Analyzer.
    
    Return ONLY valid JSON (no markdown) with exactly:
    {
      "foods_and_drink_or_not":"food_or_drink" | "not_food_or_drink",
      "drink_or_food": "drink"|"food" | "drink & food",
      "freshness":0-100,
      "label": "healthy" | "not_healthy" | "average_healthy",
      "score": 0-10,
      "action": "eat" | "limit" | "avoid",
      "calories":"...",
      "reasons": ["...","...","..."],
      "tips": ["...","..."]
    }
    
    Rules:
    - First detect if image contains food, drink, both, or not food.
    - If not food or drink, set freshness = 0 and action = "avoid".
    - Analyze freshness visually using:
       * color changes (brown, black spots, mold, dull color)
       * dryness or shrinkage
       * liquid separation
       * mold or fungus
       * damaged texture
       * excessive oil
       * cloudy drink
       * broken packaging
    - If food looks rotten, moldy, or unsafe → freshness below 30 and action = "avoid".
    - If slightly damaged or stale → freshness 30–60 and action = "limit".
    - If fresh appearance, natural color, no damage → freshness 70–100 and action = "eat".
    - Keep reasons short and practical.
    - Do NOT give medical diagnosis.
    - Avoid absolute claims.
    ''';

    final base64Image = base64Encode(bytes);

    final res = await http.post(
      Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      headers: {
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
        // OpenRouter recommends these:
        "HTTP-Referer": "http://localhost",
        "X-Title": "Flutter Food Analyzer",
      },
      body: jsonEncode({
        "model": "google/gemini-2.5-flash",
        "max_tokens": 1000,
        "messages": [
          {
            "role": "user",
            "content": [
              {"type": "text", "text": prompt},
              {
                "type": "image_url",
                "image_url": {"url": "data:$mimeType;base64,$base64Image"},
              },
            ],
          },
        ],
      }),
    );

    final data = jsonDecode(res.body);

    // If OpenRouter returns an error, show it clearly
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("OpenRouter error: ${data["error"] ?? res.body}");
    }

    final text =
        (data["choices"]?[0]?["message"]?["content"] ?? "").toString().trim();

    final jsonStr = _extractFirstJsonObject(text);
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return FoodAnalysis.fromJson(map);
  }

  String _extractFirstJsonObject(String input) {
    final start = input.indexOf('{');
    final end = input.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return json.encode({
        "foods_and_drink_or_not": "food_or_drink",
        "drink_or_food": "food",
        "label": "average",
        "freshness": 0,
        "score": 0,
        "action": "limit",
        "calories": "unknown",
        "reasons": ["Could not parse the model response as JSON."],
        "tips": ["Try taking a clearer photo with good lighting."],
      });
    }
    return input.substring(start, end + 1);
  }
}
