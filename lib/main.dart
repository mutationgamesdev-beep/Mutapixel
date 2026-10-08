import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/mutapixel_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.load();
  runApp(const SpriteBuilderApp());
}

class SpriteBuilderApp extends StatelessWidget {
  const SpriteBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Mutapixel',
          debugShowCheckedModeBanner: false,
          theme: MutapixelTheme.light(),
          darkTheme: MutapixelTheme.dark(),
          themeMode: mode,
          home: const HomeScreen(),
        );
      },
    );
  }
}
