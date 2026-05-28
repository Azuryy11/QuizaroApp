import 'package:flutter/material.dart';
import 'dart:io';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/quiz_list_screen.dart';
import 'screens/profile_screen.dart';

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
          shadowColor: neonViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: neonViolet),
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

  final String baseUrl = 'https://std37.beaupeyrat.com';

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
      _selectedIndex = 2; // Reste sur l'onglet Profil (qui affichera LoginScreen)
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        userName: _userData?['displayName'],
        baseUrl: baseUrl,
        sessionCookie: _sessionCookie,
        onNavigate: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
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
      body: screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
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
