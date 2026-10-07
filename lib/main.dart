import 'package:flutter/material.dart';

import 'screens/editor_screen.dart';

void main() {
  runApp(const SpriteBuilderApp());
}

class SpriteBuilderApp extends StatelessWidget {
  const SpriteBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sprite Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE0301E), // MutationGames red
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0E0E14),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF14141C),
          foregroundColor: Colors.white,
        ),
      ),
      home: const EditorScreen(),
    );
  }
}
