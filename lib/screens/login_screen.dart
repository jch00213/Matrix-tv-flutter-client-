import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'room_list_screen.dart';
import '../services/app_webserver.dart';
import '../utils/responsive_extension.dart';

class LoginScreen extends StatefulWidget {
  final Client client;
  const LoginScreen({super.key, required this.client});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _homeserverController = TextEditingController(text: 'https://matrix.yourdomain.com');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Validate and connect to the homeserver URL
      final homeserverUri = Uri.parse(_homeserverController.text.trim());
      await widget.client.checkHomeserver(homeserverUri);
      
      // Perform password authentication using AuthenticationUserIdentifier
      await widget.client.login(
        LoginType.mLoginPassword,
        identifier: AuthenticationUserIdentifier(
          user: _usernameController.text.trim(),
        ),
        password: _passwordController.text,
      );

      // 🔑 CRITICAL: Push the freshly authenticated client instance to the webserver
      AppWebserver().setClient(widget.client);

      // Transition straight to the room list.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomListScreen(client: widget.client),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _homeserverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool tvMode = context.isTv;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.defaultPadding),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: tvMode ? 650 : 450),
              padding: EdgeInsets.all(tvMode ? 40.0 : 32.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: tvMode ? 64 : 48,
                    color: const Color(0xFF03DAC6),
                  ),
                  SizedBox(height: tvMode ? 20 : 16),
                  Text(
                    'Matrix TV Sign In',
                    style: TextStyle(
                      fontSize: tvMode ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: tvMode ? 28 : 24),
                  TextField(
                    controller: _homeserverController,
                    style: TextStyle(fontSize: context.bodyTextSize),
                    decoration: const InputDecoration(
                      labelText: 'Homeserver URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                  ),
                  SizedBox(height: tvMode ? 20 : 16),
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(fontSize: context.bodyTextSize),
                    decoration: const InputDecoration(
                      labelText: 'Username or Matrix ID',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: tvMode ? 20 : 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: TextStyle(fontSize: context.bodyTextSize),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _handleLogin(),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    SizedBox(height: tvMode ? 20 : 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.redAccent, fontSize: context.bodyTextSize - 2),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: tvMode ? 32 : 24),
                  SizedBox(
                    height: tvMode ? 56 : 48,
                    child: ElevatedButton(
                      autofocus: tvMode, // Automatically grabs D-pad focus on TV launch
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF03DAC6),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'Connect',
                              style: TextStyle(fontSize: tvMode ? 18 : 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
