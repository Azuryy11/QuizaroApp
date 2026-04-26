import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Couleurs extraites de ton style.css
    const Color neonViolet = Color(0xFF7C3AED);
    const Color backgroundViolet = Color(0xFFF3F0FF);
    const Color textDark = Color(0xFF1E1040);

    return MaterialApp(
      title: 'Quizaro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundViolet,
        colorScheme: ColorScheme.fromSeed(
          seedColor: neonViolet,
          primary: neonViolet,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: neonViolet, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: textDark),
          bodyMedium: TextStyle(color: textDark),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: neonViolet,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: neonViolet,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonViolet,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            elevation: 2,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: neonViolet.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: neonViolet.withOpacity(0.15)),
          ),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  String? _sessionCookie;

  final String baseUrl = 'https://localhost';

  void _onLoginSuccess(Map<String, dynamic> user, String? cookie) {
    setState(() {
      _userData = user;
      _sessionCookie = cookie;
      _selectedIndex = 0;
    });
  }

  void _onLogout() {
    setState(() {
      _userData = null;
      _sessionCookie = null;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(userName: _userData?['displayName']),
      QuizListScreen(
        isAuthenticated: _userData != null, 
        baseUrl: baseUrl,
        sessionCookie: _sessionCookie,
      ),
      _userData == null 
        ? LoginScreen(onLoginSuccess: _onLoginSuccess, baseUrl: baseUrl) 
        : ProfileScreen(
            userData: _userData!, 
            onLogout: _onLogout, 
            baseUrl: baseUrl, 
            sessionCookie: _sessionCookie
          ),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Quiz'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String? userName;
  const HomeScreen({super.key, this.userName});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QUIZARO')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.2), blurRadius: 20)],
              ),
              child: const Icon(Icons.bolt, size: 80, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 30),
            Text(
              userName != null ? 'Salut, $userName !' : 'Bienvenue sur Quizaro', 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1040))
            ),
            const SizedBox(height: 10),
            const Text('Prêt à tester tes connaissances ?', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, String?) onLoginSuccess;
  final String baseUrl;
  const LoginScreen({super.key, required this.onLoginSuccess, required this.baseUrl});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest'},
        body: json.encode({'email': _emailController.text, 'password': _passwordController.text}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        String? rawCookie = response.headers['set-cookie'];
        String? cleanCookie;
        if (rawCookie != null) {
          cleanCookie = rawCookie.split(',').map((c) => c.split(';').first.trim()).where((c) => !c.contains('deleted')).join('; ');
        }
        
        Map<String, dynamic> userMap = {'displayName': _emailController.text.split('@')[0], 'email': _emailController.text};
        try {
          final data = json.decode(response.body);
          if (data['user'] != null) userMap = data['user'];
        } catch (_) {}

        widget.onLoginSuccess(userMap, cleanCookie);
      } else {
        _showError('Identifiants incorrects');
      }
    } catch (e) {
      if (mounted) _showError('Erreur réseau');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Connexion', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController, 
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController, 
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              _isLoading 
                ? const CircularProgressIndicator() 
                : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _login, child: const Text('SE CONNECTER'))),
            ],
          ),
        ),
      ),
    );
  }
}

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
      appBar: AppBar(title: const Text('LES QUIZ')),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
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
                      Navigator.push(context, MaterialPageRoute(builder: (context) => QuizGameScreen(quizId: quiz['id'], baseUrl: widget.baseUrl, sessionCookie: widget.sessionCookie)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connectez-vous pour jouer !')));
                    }
                  },
                ),
              );
            },
          ),
    );
  }
}

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
              backgroundColor: const Color(0xFF7C3AED).withOpacity(0.1),
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
      if (response.statusCode == 200) { setState(() { fullUserData = json.decode(response.body); isLoading = false; }); } 
      else { setState(() => isLoading = false); }
    } catch (e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final displayUser = fullUserData ?? widget.userData;
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
            Text(displayUser['displayName'] ?? displayUser['username'] ?? 'Utilisateur', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(displayUser['email'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: widget.onLogout, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('SE DÉCONNECTER'))),
          ],
        ),
      ),
    );
  }
}
