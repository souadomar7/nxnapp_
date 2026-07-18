import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UaePassService {
  // Singleton instance
  static final UaePassService _instance = UaePassService._internal();
  factory UaePassService() => _instance;
  UaePassService._internal();

  // Dynamic getters from dotenv configurations
  String get clientId => dotenv.env['UAE_PASS_CLIENT_ID'] ?? "sandbox_stage"; 
  String get clientSecret => dotenv.env['UAE_PASS_CLIENT_SECRET'] ?? "sandbox_stage";
  String get redirectUri => dotenv.env['UAE_PASS_REDIRECT_URI'] ?? "https://your-redirect-uri.com/callback";
  bool get isProduction => dotenv.env['UAE_PASS_IS_PRODUCTION'] == 'true'; 

  // Simulation Mode: Defaults to true unless explicitly configured to false in .env
  bool get isSimulationMode => dotenv.env['UAE_PASS_SIMULATION_MODE'] != 'false'; 

  // Endpoints
  String get _baseUrl => isProduction ? "https://id.uaepass.ae" : "https://stg-id.uaepass.ae";
  String get _authEndpoint => "$_baseUrl/idshub/authorize";
  String get _tokenEndpoint => "$_baseUrl/idshub/token";
  String get _userInfoEndpoint => "$_baseUrl/idshub/userinfo";

  /// Initiates the UAE Pass login flow.
  /// 
  /// In [isSimulationMode], returns mock data after a delay.
  /// In real mode, launches the OAuth URL.
  Future<Map<String, dynamic>?> signIn() async {
    if (isSimulationMode) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Return mock user profile
      return {
        'uuid': '123456789',
        'fullnameEN': 'Al Falak Logistics LLC',
        'fullnameAR': 'شركة الفلك للخدمات اللوجستية',
        'firstnameEN': 'Al Falak',
        'lastnameEN': 'Logistics',
        'gender': 'Male',
        'nationalityEN': 'United Arab Emirates',
        'mobile': '971509998877',
        'email': 'contact@alfalak.ae',
        'licenseNumber': 'CN-123456', // Custom field often mapped from SP attributes
        'userType': 'BUSINESS',
      };
    } else {
      // Real OAuth2 Flow
      final state = DateTime.now().millisecondsSinceEpoch.toString();
      final url = Uri.parse(
        "$_authEndpoint?response_type=code&client_id=$clientId&scope=urn:uae:digitalid:profile&state=$state&redirect_uri=$redirectUri&acr_values=urn:safelayer:tws:policies:authentication:level:low"
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        // Note: In a real app, you need to handle the Deep Link callback in your main.dart or using app_links package
        // to capture the 'code' from the Redirect URI, then call exchangeCodeForToken(code).
        // Since we don't have the deep link setup in this specific snippet, we return null here.
        return null;
      } else {
        throw 'Could not launch UAE Pass';
      }
    }
  }

  /// Exchanges the authorization code for an access token.
  Future<String?> exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        },
        body: {
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        debugPrint('UAE Pass Token Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('UAE Pass Token Exception: $e');
      return null;
    }
  }

  /// Fetches user profile using the access token.
  Future<Map<String, dynamic>?> getUserProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(_userInfoEndpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('UAE Pass User Info Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('UAE Pass User Info Exception: $e');
      return null;
    }
  }

  /// Verifies the Trade License via "Waslah" (Government Database).
  /// 
  /// In a real scenario, this calls the DED/Waslah API endpoint configured in .env.
  Future<bool> verifyTradeLicense(String licenseNo) async {
    if (isSimulationMode) {
      // Simulate API network call
      await Future.delayed(const Duration(seconds: 1));
      // Mock Logic: Accept any license starting with "CN-"
      // Reject others to demonstrate validation failure
      if (licenseNo.toUpperCase().startsWith("CN-")) {
        return true;
      }
      return false; 
    } else {
      // Real API validation using Waslah endpoint
      final url = dotenv.env['WASLAH_API_URL'];
      final apiKey = dotenv.env['WASLAH_API_KEY'];
      if (url == null || url.isEmpty) {
        // Fallback or stub success if URL not yet set up
        return true;
      }

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'trade_license_number': licenseNo,
          }),
        );
        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          return resData['is_valid'] == true;
        }
        return false;
      } catch (e) {
        debugPrint('Waslah API verification error: $e');
        return false;
      }
    }
  }
}
