import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';
import 'package:intl/intl.dart';

class GeminiService {
  static GeminiService? _instance;
  late final String _apiKey;
  
  // Using Groq API with LLama 3.1
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant'; // Fast and efficient model
  
  GeminiService._() {
    final apiKey = dotenv.env['GROQ_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your_groq_api_key_here') {
      throw Exception('GROQ_API_KEY not found or not configured in .env file');
    }
    _apiKey = apiKey;
  }
  
  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  Future<String> _generateContent(String prompt) async {
    final url = Uri.parse(_baseUrl);
    
    final requestBody = {
      'model': _model,
      'messages': [
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': 0.7,
      'max_tokens': 4096,
      'top_p': 0.95,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final choices = data['choices'] as List?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'];
        final content = message['content'];
        if (content != null) {
          return content.toString();
        }
      }
      throw Exception('Empty response from Groq');
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Groq API error: ${error['error']?['message'] ?? response.body}');
    }
  }

  Future<String> generateTripItinerary(TripRequest request) async {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final startDateStr = dateFormatter.format(request.startDate);
    
    // Build the interests section
    String interestsSection = '';
    if (request.interests != null && request.interests!.isNotEmpty) {
      interestsSection = '❤️ **Interests:** ${request.interests!.join(', ')}';
    }
    
    // Build the special requirements section
    String specialReqSection = '';
    if (request.specialRequirements != null && request.specialRequirements!.isNotEmpty) {
      specialReqSection = '📝 **Special Requirements:** ${request.specialRequirements}';
    }
    
    final prompt = '''
Create a detailed travel itinerary:

📍 ${request.destination} | 📅 $startDateStr | ⏱️ ${request.numberOfDays} days | 💰 ${request.budgetCurrency} ${request.budget.toStringAsFixed(0)}
${request.travelStyle != null ? '🎯 Style: ${request.travelStyle}' : ''}
$interestsSection
$specialReqSection

Include:
1. Trip Overview (brief intro)
2. Day-by-Day Itinerary (morning/afternoon/evening with timings, food spots, daily budget)
3. Accommodation (3 options: budget, mid-range, premium with prices)
4. Budget Breakdown (accommodation, food, transport, activities, total)
5. Packing Essentials
6. Local Tips (etiquette, money-saving, foods to try)
7. Transportation Guide (how to get there and around)
8. Emergency Info (numbers, hospitals)
${request.specialRequirements != null ? '9. Special Requirements: "${request.specialRequirements}"' : ''}

Use markdown with emojis. Keep total cost within ${request.budgetCurrency} ${request.budget.toStringAsFixed(0)}.
''';

    try {
      return await _generateContent(prompt);
    } catch (e) {
      throw Exception('Failed to generate itinerary: $e');
    }
  }

  Future<String> askTravelQuestion(String question, {String? context}) async {
    final prompt = '''
You are a helpful travel assistant. Answer the following travel-related question:

${context != null ? 'Context: $context\n\n' : ''}
Question: $question

Provide a helpful, accurate, and concise response. Include specific recommendations when appropriate.
''';

    try {
      return await _generateContent(prompt);
    } catch (e) {
      throw Exception('Failed to get response: $e');
    }
  }

  Future<List<String>> getSuggestedDestinations({
    required double budget,
    required int days,
    String? fromLocation,
    List<String>? interests,
  }) async {
    final interestsText = interests != null && interests.isNotEmpty 
        ? 'Interests: ${interests.join(", ")}' 
        : '';
    
    final prompt = '''
Suggest 5 travel destinations for a ${days}-day trip with a budget of INR ${budget.toStringAsFixed(0)}.
${fromLocation != null ? 'Traveling from: $fromLocation' : ''}
$interestsText

Return ONLY a JSON array of destination names, nothing else. Example:
["Goa, India", "Manali, India", "Udaipur, India", "Pondicherry, India", "Darjeeling, India"]
''';

    try {
      final text = (await _generateContent(prompt)).trim();
      // Parse the JSON array
      final regex = RegExp(r'\[.*\]', dotAll: true);
      final match = regex.firstMatch(text);
      if (match != null) {
        final jsonStr = match.group(0)!;
        // Simple parsing - remove brackets and split by comma
        final destinations = jsonStr
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        return destinations;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
