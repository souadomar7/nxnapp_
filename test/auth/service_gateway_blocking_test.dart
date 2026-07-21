import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:nxnapp/core/auth/user_role.dart';
import 'package:nxnapp/core/auth/user_session.dart';
import 'package:nxnapp/core/auth/unauthorized_role_exception.dart';
import 'package:nxnapp/features/chat/data/datasources/chat_gateway_source.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockHttpClient extends Mock implements http.Client {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

UserSession guestSession() => UserSession.guest;
UserSession customerSession() => const UserSession(role: UserRole.customer);

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late MockHttpClient mockHttpClient;
  const String testGatewayUrl = 'https://hvstjsygmijbvjnyiqli.supabase.co/functions/v1/ai-gateway';

  setUpAll(() {
    registerFallbackValue(Uri.parse(testGatewayUrl));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
  });

  group('ChatGatewaySource – Network RBAC Blocking Tests', () {
    test(
      'Guest calling getAiReply throws UnauthorizedRoleException BEFORE any HTTP call is made',
      () async {
        final chatSource = ChatGatewaySource(
          httpClient: mockHttpClient,
          gatewayUrl: testGatewayUrl,
          session: guestSession(),
        );

        expect(
          () async => await chatSource.getAiReply('ما هي تكاليف التخزين؟'),
          throwsA(isA<UnauthorizedRoleException>()),
        );

        verifyNever(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        );
      },
    );

    test(
      'UnauthorizedRoleException carries a descriptive message for Guest access attempts',
      () async {
        final chatSource = ChatGatewaySource(
          httpClient: mockHttpClient,
          gatewayUrl: testGatewayUrl,
          session: guestSession(),
        );

        try {
          await chatSource.getAiReply('كيف أحجز رف؟');
          fail('Expected UnauthorizedRoleException to be thrown');
        } on UnauthorizedRoleException catch (e) {
          expect(e.message, contains('Guest'));
        }
      },
    );

    test(
      'Customer calling getAiReply does NOT throw UnauthorizedRoleException and proceeds to HTTP call',
      () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"reply": "المخزن مفتوح 24 ساعة"}', 200),
        );

        final chatSource = ChatGatewaySource(
          httpClient: mockHttpClient,
          gatewayUrl: testGatewayUrl,
          session: customerSession(),
        );

        final reply = await chatSource.getAiReply('ما هي ساعات العمل؟');

        expect(reply, equals('المخزن مفتوح 24 ساعة'));
        verify(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).called(1);
      },
    );

    test(
      'ChatGatewaySource throws ClientException on non-200 HTTP response for Customer',
      () async {
        when(
          () => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"error": "Internal Server Error"}', 500),
        );

        final chatSource = ChatGatewaySource(
          httpClient: mockHttpClient,
          gatewayUrl: testGatewayUrl,
          session: customerSession(),
        );

        expect(
          () async => await chatSource.getAiReply('test query'),
          throwsA(isA<http.ClientException>()),
        );
      },
    );
  });

  group('UnauthorizedRoleException – Exception Model Tests', () {
    test('UnauthorizedRoleException is correctly structured', () {
      const exception = UnauthorizedRoleException('Test denial message');
      expect(exception.message, equals('Test denial message'));
      expect(exception.toString(), contains('UnauthorizedRoleException'));
      expect(exception.toString(), contains('Test denial message'));
    });

    test('UnauthorizedRoleException is an Exception', () {
      const exception = UnauthorizedRoleException('Test');
      expect(exception, isA<Exception>());
    });
  });
}
