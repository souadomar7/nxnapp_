import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/user_session.dart';
import '../../../../core/auth/unauthorized_role_exception.dart';

class ChatGatewaySource {
  final http.Client _httpClient;
  final String _gatewayUrl;
  final UserSession _session;

  ChatGatewaySource({
    required http.Client httpClient,
    required String gatewayUrl,
    required UserSession session,
  })  : _httpClient = httpClient,
        _gatewayUrl = gatewayUrl,
        _session = session;

  /// Communicates with the secure AI proxy gateway.
  /// Guards access by role BEFORE making any network calls.
  Future<String> getAiReply(String userPrompt) async {
    // RBAC guard: Guests cannot access AI services
    if (_session.role == UserRole.guest) {
      throw const UnauthorizedRoleException(
        'Guest users are not permitted to access the AI Copilot service.',
      );
    }

    final token = _session.rawUser != null
        ? (_session.rawUser!.appMetadata['access_token'] ?? '')
        : '';

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
