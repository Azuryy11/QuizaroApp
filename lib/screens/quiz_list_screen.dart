import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'quiz_game_screen.dart';
import 'lobby_screen.dart';

class QuizListScreen extends StatefulWidget {
  final bool isAuthenticated;
  final String baseUrl;
  final String? sessionCookie;
  const QuizListScreen({super.key, required this.isAuthenticated, required this.baseUrl, this.sessionCookie});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List quizzes = [];
  bool isLoading = true;

  Future<void> _startQuizSession(int quizId) async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/quizzes/$quizId/play'),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              sessionData: data['session'],
              baseUrl: widget.baseUrl,
              sessionCookie: widget.sessionCookie,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['message'] ?? 'Erreur lors de la création de la session')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur réseau')),
        );
      }
    }
  }

  Future<void> fetchQuizzes() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/quizzes'),
        headers: {if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!},
      );
      if (response.statusCode == 200) {
        setState(() { quizzes = json.decode(response.body)['quizzes'] ?? []; isLoading = false; });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void initState() { super.initState(); fetchQuizzes(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VOS QUIZ')),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : quizzes.isEmpty
          ? Center(
            child: Column(
            children: [
              const SizedBox(height: 16),
              const Text( "Vous n'avez pas encore créé de quiz",
                style: TextStyle(fontSize: 18, color: Color(0xFF1E1040)),
              ),
            ],
          ),
        )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(quiz['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('${quiz['questionsCount'] ?? 0} questions', style: TextStyle(color: Colors.grey[600])),
                  trailing: Icon(widget.isAuthenticated ? Icons.play_circle_fill : Icons.lock_outline, color: const Color(0xFF7C3AED), size: 32),
                  onTap: () {
                    if (widget.isAuthenticated) {
                      _startQuizSession(quiz['id']);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connectez-vous pour jouer !'))
                      );
                    }
                  },
                ),
              );
            },
          ),
    );
  }
}
