import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/pages/home_page.dart';

// Simple Theme State Provider
enum ThemeModeOption { light, dark, system }

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

void main() async {
  // Ensures binding is initialized before calling Hive
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // FIX: Open the box used by the repository
  // The name must match the string used in 'TodoRepositoryImpl'
  await Hive.openBox('todosBox');

  runApp(
    // ProviderScope is required for Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Clean Architecture Todo',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: const HomePage(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.teal,
      scaffoldBackgroundColor: Colors.grey[50],
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      // CHANGED: CardTheme -> CardThemeData
      cardTheme: const CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.teal,
      scaffoldBackgroundColor: Colors.grey[900],
      // CHANGED: CardTheme -> CardThemeData
      cardTheme: CardThemeData(
        elevation: 1,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: Colors.grey[800],
      ),
    );
  }
}
