import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const PruebasAIApp());
}

class PruebasAIApp extends StatelessWidget {
  const PruebasAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PruebasAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
