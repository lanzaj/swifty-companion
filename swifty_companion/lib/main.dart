import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/search_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();
  final _storage = const FlutterSecureStorage();
  StreamSubscription<Uri>? _linkSubscription;

  // Backend URL - Change this to your machine's IP if running on physical device
  // Android Emulator uses 10.0.2.2 to access host localhost
  String get _backendUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _checkAuth();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      _navigateToHome(token);
    }
  }

  Future<void> _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (uri.scheme == 'swiftycompanion' && uri.host == 'auth') {
          final code = uri.queryParameters['code'];
          final token = uri.queryParameters['token'];

          if (code != null) {
            _exchangeCodeForToken(code);
          } else if (token != null) {
            _handleLoginSuccess(token);
          }
        }
      },
      onError: (err) {
        debugPrint("Deep link error: $err");
      },
    );
  }

  Future<void> _exchangeCodeForToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'redirect_uri': 'swiftycompanion://auth',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];
        debugPrint('Token: $token');
        debugPrint('Refresh Token: $refreshToken');
        if (token != null) {
          _handleLoginSuccess(token, refreshToken);
        } else {
          debugPrint('No access token in response: ${response.body}');
        }
      } else {
        debugPrint('Failed to exchange token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error exchanging token: $e');
    }
  }

  Future<void> _handleLoginSuccess(String token, [String? refreshToken]) async {
    await _storage.write(key: 'access_token', value: token);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    _navigateToHome(token);
  }

  void _navigateToHome(String token) {
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => SearchPage(logout: _logout)),
    );
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    _navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage(onLogin: _login)),
    );
  }

  Future<void> _login() async {
    final url = Uri.parse('$_backendUrl/auth/login');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      home: LoginPage(onLogin: _login),
      theme: ThemeData(fontFamily: 'Roboto', primaryColor: Colors.black),
    );
  }
}

class LoginPage extends StatelessWidget {
  final VoidCallback? onLogin;

  const LoginPage({super.key, this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Sign in with',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  SvgPicture.asset(
                    'assets/images/42_logo.svg',
                    height: 30,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
