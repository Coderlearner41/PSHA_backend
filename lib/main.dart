import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Screens/splash_screen.dart'; // Ensure this path matches your file structure

void main() {
  // Initialize bindings but do NOT await the DB here
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SlopeSafeApp());
}

class SlopeSafeApp extends StatelessWidget {
  const SlopeSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digiquake India',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
          primary: const Color(0xFF8B5E3C),
          secondary: const Color(0xFF0077B6),
          tertiary: const Color(0xFFFFD60A),
          onPrimary: Colors.brown,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      // The app now starts with the Splash Screen
      home: const SplashScreen(),
    );
  }
}