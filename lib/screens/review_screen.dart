import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final Map<String, dynamic>? quiz;
  final List<dynamic>? userAnswers; // Ajout des réponses du joueur

  const ReviewScreen({super.key, required this.quiz, this.userAnswers});

  @override
  Widget build(BuildContext context) {
    const Color neonViolet = Color(0xFF7C3AED);

    final dynamic rawData = quiz?['questions'];
    final List questions = (rawData is List) ? rawData : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
            (quiz?['title'] ?? 'CORRECTION').toString().toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1040),
        elevation: 0,
        centerTitle: true,
      ),
      body: questions.isEmpty
          ? const Center(child: Text("Aucune question à afficher"))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          final List answers = (question is Map) ? (question['answers'] ?? []) : [];
          final questionId = (question is Map) ? question['id'] : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: neonViolet.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Question ${index + 1}",
                    style: const TextStyle(color: neonViolet, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (question is Map) ? (question['label'] ?? '') : '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1040)),
                  ),
                  const SizedBox(height: 20),
                  ...answers.map((answer) {
                    final answerId = (answer is Map) ? answer['id'] : null;
                    final bool isCorrect = (answer is Map) ? (answer['isCorrect'] ?? false) : false;

                    // Détecter si le joueur a coché cette réponse (Comparaison ROBUSTE)
                    bool isSelectedByMe = false;
                    if (userAnswers != null && questionId != null && answerId != null) {
                      isSelectedByMe = userAnswers!.any((ua) {
                        final String uaQId = ua['questionId'].toString();
                        final String currentQId = questionId.toString();

                        if (uaQId == currentQId) {
                          final List uaAIds = ua['answerIds'] as List;
                          return uaAIds.any((id) => id.toString() == answerId.toString());
                        }
                        return false;
                      });
                    }

                    // Logique des couleurs
                    Color bgColor = Colors.white;
                    Color borderColor = Colors.grey.withOpacity(0.2);
                    Color textColor = const Color(0xFF4A4A4A);
                    IconData icon = Icons.circle_outlined;
                    Color iconColor = Colors.grey.withOpacity(0.5);

                    if (isCorrect) {
                      bgColor = const Color(0xFFE8F5E9);
                      borderColor = Colors.green.withOpacity(0.5);
                      textColor = const Color(0xFF1B5E20);
                      icon = Icons.check_circle_rounded;
                      iconColor = Colors.green;
                    } else if (isSelectedByMe && !isCorrect) {
                      bgColor = const Color(0xFFFFEBEE);
                      borderColor = Colors.red.withOpacity(0.5);
                      textColor = const Color(0xFFB71C1C);
                      icon = Icons.cancel_rounded;
                      iconColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: (isCorrect || isSelectedByMe) ? 2 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              (answer is Map) ? (answer['content'] ?? '') : '',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: (isCorrect || isSelectedByMe) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isSelectedByMe)
                            Container(
                              margin: const EdgeInsets.only(left:8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isCorrect ? Colors.green : Colors.red).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "VOTRE CHOIX",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isCorrect ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}