import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onLogout;
  final String baseUrl;
  final String? sessionCookie;
  const ProfileScreen({super.key, required this.userData, required this.onLogout, required this.baseUrl, this.sessionCookie});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? fullUserData;
  bool isLoading = true;

  @override
  void initState() { super.initState(); _fetchFullProfile(); }

  Future<void> _fetchFullProfile() async {
    try {
      final response = await http.get(Uri.parse('${widget.baseUrl}/api/auth/me'), headers: {'Accept': 'application/json', if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { fullUserData = data['user']; isLoading = false; }); } 
      else { setState(() => isLoading = false); }
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final displayUser = fullUserData;
    if (displayUser == null) {
      return const Center(child: Text('Erreur de chargement'));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
              child: const CircleAvatar(radius: 60, backgroundColor: Colors.white, child: Icon(Icons.person, size: 80, color: Color(0xFF7C3AED))),
            ),
            const SizedBox(height: 24),
            Text("Bienvenue ${displayUser['displayName'] ?? displayUser['username'] ?? 'Utilisateur'}", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Email : ${displayUser['email'] ?? ''}", style: const TextStyle(fontSize: 16)),
            Text("Quiz créés : ${displayUser['quizzesCount'] ?? 0}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: widget.onLogout, style: OutlinedButton.styleFrom(foregroundColor: Colors.black), child: const Text('Se déconnecter'))),
          ],
        ),
      ),
    );
  }
}
