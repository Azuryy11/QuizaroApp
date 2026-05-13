import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? userName;
  final Function(int) onNavigate;
  final String baseUrl;
  final String? sessionCookie;

  const HomeScreen({
    super.key,
    this.userName,
    required this.onNavigate,
    required this.baseUrl,
    this.sessionCookie,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  void _showPseudoDialog() {
    final TextEditingController pseudoController = TextEditingController();

    showDialog(
      context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Rejoindre en tant qu'invité"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Veuillez choisir un pseudo"),
                const SizedBox(height: 10),
                TextField(
                  controller: pseudoController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Pseudo",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                onPressed: () {
                  final pseudo = pseudoController.text.trim();
                  if (pseudo.isNotEmpty) {
                    Navigator.pop(context);
                    _joinSession(pseudo);
                  }
                },
                child: const Text("Rejoindre"),
              ),
            ],
          );
        },
    );
  }

  Future<void> _joinSession([String? pseudo]) async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/quiz-sessions/join'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
        },
        body: json.encode({'code': code, 'nickname': pseudo}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('--- DEBUG HOME JOIN ---');
        debugPrint('Response data: $data');

        Map<String, dynamic> sessionData = Map<String, dynamic>.from(data['session']);
        if (data['playerToken'] != null) {
          sessionData['playerToken'] = data['playerToken'];
        }
        // On conserve les données du quiz pour éviter de les re-télécharger
        if (data['quiz'] != null) {
          sessionData['quizData'] = data['quiz'];
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              sessionData: sessionData,
              baseUrl: widget.baseUrl,
              sessionCookie: widget.sessionCookie,
            ),
          ),
        );
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Session introuvable')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUIZARO')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7C3AED)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bienvenue ${widget.userName ?? ''}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1040))),
                  const SizedBox(height: 10),
                  const Text("Un site de quiz en ligne pour petit et grand",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF1E1040), fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => widget.onNavigate(1),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                          child: const Text('Jouer un quiz'),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Divider(height: 40, thickness: 1),
                  const Text('Code de session',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1040))),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'ABC123',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (widget.sessionCookie != null) {
                          _joinSession();
                        } else {
                          _showPseudoDialog();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F0FF),
                        foregroundColor: const Color(0xFF1E1040),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF7C3AED), width: 0.5),
                      ),
                      child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Rejoindre'),
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
