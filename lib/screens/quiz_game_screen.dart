import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuizGameScreen extends StatefulWidget {
  final int quizId;
  final String baseUrl;
  final String? sessionCookie;
  const QuizGameScreen({super.key, required this.quizId, required this.baseUrl, this.sessionCookie});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  Map<String, dynamic>? quizData;
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool showResult = false;

  @override
  void initState() { super.initState(); _loadQuiz(); }

  Future<void> _loadQuiz() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/quizzes/${widget.quizId}'),
        headers: {'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest', if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!},
      );
      if (response.statusCode == 200) {
        setState(() { quizData = json.decode(response.body)['quiz']; isLoading = false; });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _answerQuestion(bool isCorrect) {
    if (isCorrect) score++;
    setState(() {
      if (currentQuestionIndex < (quizData!['questions'] as List).length - 1) {
        currentQuestionIndex++;
      } else {
        showResult = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (quizData == null) return const Scaffold(body: Center(child: Text('Erreur de chargement')));

    if (showResult) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                const SizedBox(height: 24),
                const Text('TERMINÉ !', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF7C3AED))),
                const SizedBox(height: 8),
                Text('Score final : $score / ${(quizData!['questions'] as List).length}', style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 48),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('RETOUR'))),
              ],
            ),
          ),
        ),
      );
    }

    final question = quizData!['questions'][currentQuestionIndex];
    final answers = question['answers'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / (quizData!['questions'] as List).length,
              backgroundColor: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
            const SizedBox(height: 40),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(question['label'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView(
                children: answers.map((answer) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () => _answerQuestion(answer['isCorrect'] == true),
                    child: Text(answer['content'], style: const TextStyle(fontSize: 18, color: Color(0xFF1E1040), fontWeight: FontWeight.w600)),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
