import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/supabase_client.dart';

class ChatGatewaySource {
  final http.Client _httpClient;
  final String _gatewayUrl;

  ChatGatewaySource({
    required http.Client httpClient,
    required String gatewayUrl,
  })  : _httpClient = httpClient,
        _gatewayUrl = gatewayUrl;

  /// Communicates with the secure AI proxy gateway.
  /// Standard client-side SDK dependencies are deleted to safeguard API credentials.
  Future<String> getAiReply(String userPrompt) async {
    final token = SupabaseClientWrapper.instance.authHeader;

    final response = await _httpClient.post(
      Uri.parse(_gatewayUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': userPrompt,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? data['response'] ?? '';
    } else {
      throw http.ClientException(
        'AI Proxy returned error status: ${response.statusCode}',
        Uri.parse(_gatewayUrl),
      );
    }
  }
}
