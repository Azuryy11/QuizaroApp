import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, String?) onLoginSuccess;
  final String baseUrl;
  const LoginScreen({super.key, required this.onLoginSuccess, required this.baseUrl});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest'},
        body: json.encode({'email': _emailController.text, 'password': _passwordController.text}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        String? rawCookie = response.headers['set-cookie'];
        String? cleanCookie;
        if (rawCookie != null) {
          cleanCookie = rawCookie.split(',').map((c) => c.split(';').first.trim()).where((c) => !c.contains('deleted')).join('; ');
        }
        
        Map<String, dynamic> userMap = {'displayName': _emailController.text.split('@')[0], 'email': _emailController.text};
        try {
          final data = json.decode(response.body);
          if (data['user'] != null) userMap = data['user'];
        } catch (_) {}

        widget.onLoginSuccess(userMap, cleanCookie);
      } else {
        _showError('Identifiants incorrects');
      }
    } catch (e) {
      if (mounted) _showError('Erreur réseau');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Connexion', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController, 
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, 
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading 
                ? const CircularProgressIndicator() 
                : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _login, child: const Text('SE CONNECTER'))),
            ],
          ),
        ),
      ),
    );
  }
}
