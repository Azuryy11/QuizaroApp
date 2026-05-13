import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'results_screen.dart';

class QuizGameScreen extends StatefulWidget {
  final int quizId;
  final int quizSessionId;
  final String? playerToken;
  final String baseUrl;
  final String? sessionCookie;
  final Map<String, dynamic>? initialQuizData;

  const QuizGameScreen({
    super.key,
    required this.quizId,
    required this.quizSessionId,
    this.playerToken,
    required this.baseUrl,
    this.sessionCookie,
    this.initialQuizData,
  });

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  List<Map<String, dynamic>> _collectedAnswers = [];
  DateTime? _questionStartTime;
  Map<String, dynamic>? quizData;
  int currentQuestionIndex = 0;
  int score = 0;
  bool isLoading = true;
  bool showResult = false;
  Timer? _timer;
  int _timeLeft = 15;
  final int _maxTime = 15;

  @override
  void initState() { 
    super.initState();
    if (widget.initialQuizData != null) {
      quizData = widget.initialQuizData;
      isLoading = false;
      _startTimer();
    } else {
      _loadQuiz();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    final url = '${widget.baseUrl}/api/quizzes/${widget.quizId}';
    debugPrint('--- DEBUG QUIZ_GAME LOAD ---');
    debugPrint('Appel URL: $url');
    debugPrint('Token: ${widget.playerToken}');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json', 
          'X-Requested-With': 'XMLHttpRequest', 
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
          if (widget.playerToken != null) 'X-Player-Token': widget.playerToken!,
        },
      );
      
      debugPrint('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Données reçues: ${data.containsKey('quiz')}');
        setState(() { quizData = data['quiz']; isLoading = false; });
        _startTimer();
      } else {
        debugPrint('Erreur chargement: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Exception chargement: $e');
      setState(() => isLoading = false);
      _startTimer();
    }
  }

  void _answerQuestion(int? answerId, bool isCorrect) {
    _timer?.cancel();

    final responseTime = DateTime.now().difference(_questionStartTime!).inMilliseconds;

    _collectedAnswers.add({
      "questionId": quizData!['questions'][currentQuestionIndex]['id'],
      "answerIds": answerId != null ? [answerId] : [],
      "responseTimeMs": responseTime,
    });

    if (isCorrect) score++;

    setState(() {
      if (currentQuestionIndex < (quizData!['questions'] as List).length - 1) {
        currentQuestionIndex++;
        _startTimer();
      } else {
        _submitAnswers();
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
            TweenAnimationBuilder<double>(
              key: ValueKey(currentQuestionIndex),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              tween: Tween<double>(begin: 1.0, end: _timeLeft / _maxTime),
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[300],
                  color: value < (5 / _maxTime) ? Colors.redAccent : const Color(0xFF7C3AED),
                  minHeight: 6,
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              "$_timeLeft secondes restantes",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _timeLeft < 5 ? Colors.redAccent : Color(0xFF7C3AED),
              ),
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
                children: [
                  ...answers.map((answer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: Colors.white,
                      ),
                      onPressed: () => _answerQuestion(answer['id'], answer['isCorrect'] == true),
                      child: Text(answer['content'], style: const TextStyle(fontSize: 18, color: Color(0xFF1E1040), fontWeight: FontWeight.w600)),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _startTimer() {
    _timer?.cancel();
    _questionStartTime = DateTime.now();
    setState(() => _timeLeft = _maxTime);

    _timer?.cancel();
    setState(() => _timeLeft = _maxTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          timer.cancel();
          _answerQuestion(null, false);
        }
      });
    });
  }

  Future<void> _submitAnswers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/quizzes/${widget.quizId}/submit'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
          if (widget.playerToken != null) 'X-Player-Token': widget
              .playerToken!,
        },
        body: json.encode({
          'quizSessionId': widget.quizSessionId,
          'answers': _collectedAnswers,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultsScreen(
                  quizSessionId: widget.quizSessionId,
                  baseUrl: widget.baseUrl,
                  sessionCookie: widget.sessionCookie,
                  playerToken: widget.playerToken,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur submit: $e');
    }
  }
}
