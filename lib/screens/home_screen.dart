import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String? userName;
  final Function(int) onNavigate;
  const HomeScreen({super.key, this.userName, required this.onNavigate});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUIZARO')),
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                const Text('Bienvenue sur Quizaro',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1040))
                ),
                const SizedBox(height: 10),
                const Text("Un site de quiz en ligne pour petit et grand", style: TextStyle(color: Color(0xFF1E1040), fontSize: 16)),
                const SizedBox(height: 20),
                Row (
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                        child: const Text('Créer un quiz'),
                      ),
                    ),
                    const SizedBox(width:16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {onNavigate(1);},
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.black),
                        child: const Text('Jouer un quiz'),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(height: 40, thickness: 1),
                const Text('Code de session',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1040))
                ),
                const SizedBox(height: 20),
                TextField(
                  textAlign: TextAlign.center,
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
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F0FF),
                      foregroundColor: const Color(0xFF1E1040),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF7C3AED), width: 0.5),
                    ),
                    child: const Text('Rejoindre'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
