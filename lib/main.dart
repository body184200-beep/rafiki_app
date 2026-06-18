import 'dart:async';
import 'package:flutter/material.dart';
import 'botimNavigationBar/Main_Screen/Start.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return; // ✅ تجنب crash لو الـ widget اتشال
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Start()),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05211B), // Rich dark emerald green to blend with the splash screen
      body: SizedBox.expand(
        child: Image.asset(
          'assets/rafiki.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}