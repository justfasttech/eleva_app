import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

class AiContentService {
  static Future<Map<String, dynamic>> generateReading({
    required String themeName,
    required String category,
    required int level,
  }) async {
    return _invoke({
      'type': 'reading',
      'theme_name': themeName,
      'category': category,
      'level': level,
    });
  }

  static Future<Map<String, dynamic>> generatePrayer({
    required String themeName,
  }) async {
    return _invoke({
      'type': 'prayer',
      'theme_name': themeName,
    });
  }

  static Future<Map<String, dynamic>> generateQuiz({
    required String themeName,
  }) async {
    return _invoke({
      'type': 'quiz',
      'theme_name': themeName,
    });
  }

  static Future<Map<String, dynamic>> _invoke(
      Map<String, dynamic> body) async {
    final response =
        await Supabase.instance.client.functions.invoke(
      'generate-content',
      body: body,
    );

    if (response.status != 200) {
      final msg = response.data is Map
          ? response.data['error'] ?? 'Erro desconhecido'
          : 'Erro ao gerar conteúdo';
      throw Exception(msg);
    }

    final data = response.data;
    if (data is String) return jsonDecode(data) as Map<String, dynamic>;
    if (data is Map<String, dynamic>) return data;
    throw Exception('Resposta inesperada da IA');
  }
}
