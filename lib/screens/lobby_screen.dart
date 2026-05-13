import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:qr_flutter/qr_flutter.dart';
import 'quiz_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final String baseUrl;
  final String? sessionCookie;

  const LobbyScreen({
    super.key,
    required this.sessionData,
    required this.baseUrl,
    this.sessionCookie,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  late Map<String, dynamic> _currentSession;
  late int _sessionId;
  Timer? _pollingTimer;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.sessionData;
    _sessionId = widget.sessionData['quizSessionId'] ?? widget.sessionData['id'];
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final url = '${widget.baseUrl}/api/quiz-sessions/$_sessionId/lobby';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
            if (widget.sessionData['playerToken'] != null) 'X-Player-Token': widget.sessionData['playerToken'],
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(() {
              _currentSession = data['session'];
            });

            if (_currentSession['status'] == 'RUNNING') {
              _pollingTimer?.cancel();
              _navigateToQuiz();
            }
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  Future<void> _startSession() async {
    setState(() => _isStarting = true);
    try {
      final url = '${widget.baseUrl}/api/quiz-sessions/$_sessionId/start';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!
        },
      );

      if (response.statusCode == 200) {
        _pollingTimer?.cancel();
        _navigateToQuiz();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors du lancement')));
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  void _navigateToQuiz() {
    if (!mounted) return;
    
    final quizId = _currentSession['quizId'] ?? 
                  (_currentSession['quiz'] is Map ? _currentSession['quiz']['id'] : null) ??
                  widget.sessionData['quizId'] ??
                  (widget.sessionData['quiz'] is Map ? widget.sessionData['quiz']['id'] : null);

    if (quizId == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizGameScreen(
          quizId: quizId,
          quizSessionId: _sessionId,
          playerToken: widget.sessionData['playerToken'],
          baseUrl: widget.baseUrl,
          sessionCookie: widget.sessionCookie,
          initialQuizData: widget.sessionData['quizData'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _currentSession['isOwner'] ?? false;
    const Color neonViolet = Color(0xFF7C3AED);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SALLE D\'ATTENTE'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1040),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: neonViolet.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: neonViolet.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  widget.sessionData['quizTitle'] ?? '',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1040)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                const Text("CODE DE SESSION", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  _currentSession['code'] ?? '---',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 4, color: neonViolet),
                ),
                const SizedBox(height: 30),

                if (isOwner)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QrImageView(
                        data: "${widget.baseUrl}:5173/#/waiting-session/${_currentSession['quizSessionId']}",
                        version: QrVersions.auto,
                        size: 180.0,
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.people, color: neonViolet),
                    const SizedBox(width: 8),
                    Text(
                      "${_currentSession['playerCount'] ?? 0} JOUEURS CONNECTÉS",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1040)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                if (_currentSession['players'] != null && (_currentSession['players'] as List).isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ...(_currentSession['players'] as List).map((p) {
                        String name = p is Map ? (p['nickname'] ?? 'Anonyme') : p.toString();
                        return Chip(
                          label: Text(name, style: const TextStyle(color: neonViolet, fontWeight: FontWeight.bold)),
                          backgroundColor: neonViolet.withOpacity(0.1),
                          side: const BorderSide(color: neonViolet),
                        );
                      }),
                    ],
                  ),

                const SizedBox(height: 40),

                if (isOwner)
                  _isStarting
                      ? const CircularProgressIndicator(color: neonViolet)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _startSession,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: neonViolet,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('LANCER LE QUIZ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),

                if (!isOwner)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: neonViolet),
                      const SizedBox(height: 20),
                      const Text(
                        "En attente du démarrage par le créateur...",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
