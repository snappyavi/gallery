import 'package:flutter/material.dart';
import 'package:gallery_by_osolution/home_page.dart';
// Import your main screen

class ModernSplashScreen extends StatefulWidget {
  const ModernSplashScreen({super.key});

  @override
  _ModernSplashScreenState createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends State<ModernSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading time or perform initial setup.
    _navigateToHome();
  }

  _navigateToHome() async {
    // Simulate a delay (e.g., loading data, checking authentication).
    await Future.delayed(const Duration(milliseconds: 1000));

    // Navigate to your main screen.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainGalleryApp(),
      ), // Replace with your main screen widget
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get MediaQuery data once for efficiency
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final screenWidth = mq.size.width;

    // Responsive calculations - keep original structure but use percentages
    final logoTopPadding = screenHeight * 0.4; // Instead of hardcoded 268.0
    final logoHeight =
        screenHeight * 0.15; // Same as top padding for consistency
    final double titleFontSize = (screenWidth * 0.08).clamp(
      20,
      40,
    ); // Clamp between 20-40
    final double subtitleFontSize = (screenWidth * 0.04).clamp(
      12,
      20,
    ); // Clamp between 12-20
    final verticalSpacing = screenHeight * 0.02; // Instead of hardcoded values
    final bottomPadding = screenHeight * 0.06; // Bottom spacing

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Background decoration - unchanged
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content - same structure, responsive values
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo section - responsive but same structure
              Padding(
                padding: EdgeInsets.only(top: logoTopPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: logoHeight,
                        width: logoHeight,
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    Text(
                      'Gallery by OSol',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Bottom text section - responsive padding and font sizes
              Padding(
                padding: EdgeInsets.only(
                  left: screenWidth * 0.05, // Instead of hardcoded 20
                  right: screenWidth * 0.05,
                  bottom: bottomPadding,
                ),
                child: Column(
                  children: [
                    Text(
                      'Made in 🇮🇳 with ❤️',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    //SizedBox(height: verticalSpacing),
                    Text(
                      'Offline by design, private by default',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
