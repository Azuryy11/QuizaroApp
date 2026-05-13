import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:quizaro_mobile/screens/review_screen.dart';

class ResultsScreen extends StatefulWidget {
  final int quizSessionId;
  final String baseUrl;
  final String? sessionCookie;
  final String? playerToken;

  const ResultsScreen({
    super.key,
    required this.quizSessionId,
    required this.baseUrl,
    this.sessionCookie,
    this.playerToken,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  Map<String, dynamic>? resultsData;
  Timer? _pollingTimer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (resultsData?['session']?['status'] != 'FINISHED') {
        _fetchResults();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.baseUrl}/api/quiz-sessions/${widget.quizSessionId}/results'),
        headers: {
          'Accept': 'application/json',
          if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
          if (widget.playerToken != null) 'X-Player-Token': widget.playerToken!,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            resultsData = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur chargement résultats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color neonViolet = Color(0xFF7C3AED);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: neonViolet)));
    }

    final session = resultsData!['session'];
    final quiz = resultsData!['quiz'];
    final results = resultsData!['results'] as List;
    
    final int totalQuestions = quiz['totalQuestions'] ?? 
                               (quiz['questions'] is List ? (quiz['questions'] as List).length : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RÉSULTATS FINAUX', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1040),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              "QUITTER",
              style: TextStyle(color: neonViolet, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Quiz Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: neonViolet.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(quiz['title'] ?? 'Quiz', textAlign: TextAlign.center, 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: neonViolet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("Code : ${session['code']}", 
                        style: const TextStyle(color: neonViolet, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Titre Classement
            const Center(
              child: Text(
                "CLASSEMENT",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF1E1040),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scoreboard Table (Légèrement rétréci)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias, 
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.0), // Rank
                    1: FlexColumnWidth(2.6), // Joueur
                    2: FlexColumnWidth(2.1), // Score
                    3: FlexColumnWidth(1.2), // %
                    4: FlexColumnWidth(2.5), // Statut
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // En-tête mauve
                    TableRow(
                      decoration: const BoxDecoration(color: neonViolet),
                      children: [
                        _buildHeaderCell('Rank'),
                        _buildHeaderCell('Joueur'),
                        _buildHeaderCell('Score'),
                        _buildHeaderCell('%'),
                        _buildHeaderCell('Statut'),
                      ],
                    ),
                    // Joueurs
                    ...results.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final player = entry.value;
                      final bool isMe = player['isMe'] ?? false;
                      final int score = player['score'] ?? 0;
                      final double percentage = totalQuestions > 0 ? (score / totalQuestions * 100) : 0;
                      final bool isFinished = player['finishedAt'] != null;

                      final Color rowColor;
                      if (isMe) {
                        rowColor = const Color(0xFFE5DDFB); // rgb(229, 221, 251)
                      } else {
                        rowColor = index.isEven ? const Color(0xFFF4F0FE) : Colors.white;
                      }

                      return TableRow(
                        decoration: BoxDecoration(
                          color: rowColor,
                          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
                        ),
                        children: [
                          _buildDataCell("${player['rank']}"),
                          _buildDataCell(player['nickname'], isMe: isMe, isNickname: true),
                          _buildDataCell("$score/$totalQuestions"),
                          _buildDataCell("${percentage.round()}%"),
                          _buildStatusCell(isFinished),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // Bouton Correction
            ElevatedButton.icon(
              onPressed: () async {
                if (resultsData == null) return;

                final quizInfo = resultsData!['quiz'];
                var questionsList = quizInfo['questions'] ?? resultsData!['questions'];

                // Si les questions sont manquantes, on va les chercher sur l'API du quiz
                if (questionsList == null || (questionsList is List && questionsList.isEmpty)) {
                  try {
                    // On affiche un loader temporaire
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: neonViolet)),
                    );

                    // Gestion de l'ID (peut être un int ou une IRI string "/api/quizzes/5")
                    String quizIdStr = quizInfo['id'].toString();
                    if (quizIdStr.contains('/')) {
                      quizIdStr = quizIdStr.split('/').last;
                    }

                    final response = await http.get(
                      Uri.parse('${widget.baseUrl}/api/quizzes/$quizIdStr'),
                      headers: {
                        'Accept': 'application/json',
                        if (widget.sessionCookie != null) 'cookie': widget.sessionCookie!,
                        if (widget.playerToken != null) 'X-Player-Token': widget.playerToken!,
                      },
                    );

                    if (!mounted) return;
                    Navigator.pop(context); // Fermer le loader

                    if (response.statusCode == 200) {
                      final fullData = json.decode(response.body);
                      // Dans Symfony, le quiz est souvent dans fullData['quiz']
                      final Map<String, dynamic> quizMap = fullData['quiz'] ?? fullData;
                      final dynamic rawQuestions = quizMap['questions'] ?? fullData['questions'];

                      if (rawQuestions is List) {
                        questionsList = rawQuestions;
                      }
                      
                      debugPrint("DEBUG: Nombre de questions trouvées = ${questionsList?.length}");
                    } else {
                      debugPrint("ERREUR API QUIZ: ${response.statusCode} - ${response.body}");
                    }
                  } catch (e) {
                    if (mounted) Navigator.pop(context);
                    debugPrint("EXCEPTION: $e");
                  }
                }

                if (questionsList != null && questionsList is List && questionsList.isNotEmpty) {
                  if (!mounted) return;
                  
                  debugPrint("NAVIGATION VERS REVIEW: Envoi de ${questionsList.length} questions");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewScreen(
                        quiz: {
                          'title': resultsData?['quiz']?['title'] ?? 'Correction',
                          'questions': questionsList,
                        },
                      ),
                    ),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Les questions n'ont pas pu être chargées (Liste vide).")),
                    );
                  }
                }
              },
              icon: const Icon(Icons.checklist_rtl),
              label: const Text("Voir les réponses", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isMe = false, bool alignLeft = false, bool isNickname = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.black,
          fontWeight: (isMe && isNickname) ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatusCell(bool isFinished) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        isFinished ? 'Terminé' : 'En attente',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isFinished ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}
