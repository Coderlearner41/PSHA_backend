import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../services/local_hazard_service.dart';
import 'map_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = "Initializing...";
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // 1. Start the DB initialization (Copying the 74MB file)
      // This happens while the user sees the logo and spinner
      await LocalHazardService.initDB();
      
      // 2. Minimum delay to ensure the splash animation is seen
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (_, __, ___) => const MapScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = "Database Error: $e";
          _isError = true;
        });
      }
    }
  }

  // Helper widget to build the profile pictures with names
  Widget _buildProfile(String imagePath, String name) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: CircleAvatar(
            radius: 35, // Adjust this size if the pictures are too big/small
            backgroundImage: AssetImage(imagePath),
            backgroundColor: Colors.white12, // Fallback color while loading
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF1C130E), // Using your dark theme color instead of basic brown
      body: SafeArea(
        child: Center(
          child: ZoomIn(
            duration: const Duration(milliseconds: 1500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Main Logo
                Hero(
                  tag: 'logo',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Image.asset(
                      'assets/logo.png',
                      width: screenWidth * 0.65, 
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Spinner and Status
                if (!_isError) 
                  const CircularProgressIndicator(color: Colors.white70),
                const SizedBox(height: 20),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isError ? Colors.redAccent : Colors.white70,
                    fontSize: 14,
                  ),
                ),
                
                const Spacer(),
                
                // Horizontal Team Profiles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildProfile('assets/Dhawal_Khatri.jpg', 'Dhawal\nKhatri'),
                      ),
                      Expanded(
                        child: _buildProfile('assets/Ajay_Kumar_Pathak.jpeg', 'Ajay Kumar\nPathak'),
                      ),
                      Expanded(
                        child: _buildProfile('assets/proff._STG_Ragukanth.jpg', 'Prof. STG\nRaghukanth'),
                      ),
                    ],
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