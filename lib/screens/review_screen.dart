import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final Map<String, dynamic>? quiz;

  const ReviewScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    const Color neonViolet = Color(0xFF7C3AED);

    // Récupération ultra-sécurisée des questions
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
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("Aucune question à afficher", style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("RETOUR"),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              final List answers = (question is Map)
                  ? (question['answers'] ?? question['options'] ?? [])
                  : [];

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: neonViolet.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: neonViolet.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: neonViolet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(color: neonViolet, fontWeight: FontWeight.w900, fontSize: 16)
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              (question is Map)
                                  ? (question['label'] ?? question['questionText'] ?? question['text'] ?? 'Question sans texte')
                                  : 'Structure de question invalide',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF1E1040),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...answers.map((answer) {
                        final bool isCorrect = (answer is Map)
                            ? (answer['isCorrect'] ?? answer['correct'] ?? false)
                            : false;
                        final String text = (answer is Map)
                            ? (answer['content'] ?? answer['answerText'] ?? answer['label'] ?? '')
                            : '';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isCorrect ? const Color(0xFFE8F5E9) : Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isCorrect ? Colors.green.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
                              width: isCorrect ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect ? Icons.check_circle_rounded : Icons.circle_outlined,
                                color: isCorrect ? Colors.green : Colors.grey.withOpacity(0.5),
                                size: 24,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    color: isCorrect ? const Color(0xFF1B5E20) : const Color(0xFF4A4A4A),
                                    fontWeight: isCorrect ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 16,
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
