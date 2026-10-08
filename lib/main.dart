import 'package:flutter/material.dart';

import 'screens/editor_screen.dart';
import 'theme/mutapixel_theme.dart';

void main() {
  runApp(const SpriteBuilderApp());
}

class SpriteBuilderApp extends StatelessWidget {
  const SpriteBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mutapixel',
      debugShowCheckedModeBanner: false,
      theme: MutapixelTheme.light(),
      home: const EditorScreen(),
    );
  }
}
