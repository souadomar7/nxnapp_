import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRemoteDataSource {
  final http.Client _httpClient;
  final String _edgeFunctionUrl;

  ChatRemoteDataSource({
    required http.Client httpClient,
    required String edgeFunctionUrl,
  })  : _httpClient = httpClient,
        _edgeFunctionUrl = edgeFunctionUrl;

  /// Sends the user support query to the secure backend AI gateway.
  /// Authorization tokens are passed via headers to prevent client-side API key leakage.
  Future<String> sendPrompt(String prompt) async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken ?? '';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'prompt': prompt,
    });

    try {
      final response = await _httpClient.post(
        Uri.parse(_edgeFunctionUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? data['response'] ?? '';
      } else {
        throw http.ClientException(
          'Failed to communicate with gateway AI service. Status: ${response.statusCode}',
          Uri.parse(_edgeFunctionUrl),
        );
      }
    } catch (e) {
      throw Exception('Network connection error: $e');
    }
  }
}
