import 'package:flutter/material.dart';
import 'package:redebugger/auth/sign_in_screen.dart';
import 'package:redebugger/theme/theme.dart'; // Brought your theme ecosystem in

class Startscreen extends StatelessWidget {
  const Startscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // double.infinity is cleaner than MediaQuery for filling the screen
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/default_1.jpg'),
            fit: BoxFit.cover,
           
          ),
        ),
        child: SafeArea( // Ensures UI doesn't clip into the device notch/taskbar
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wrapped in a Hero widget to future-proof for splash screen animations
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'images/logo.png', 
                    width: 250, 
                    height: 250,
                  ),
                ),
                // Replaced your Transform.translate hack with scalable spatial architecture
                const SizedBox(height: 40), 

                // Continue button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(250, 55), // Nuked the weird leading zero
                    backgroundColor: AppTheme.primaryColor, // Synergized with your global theme
                    foregroundColor: Colors.white,
                    elevation: 8, // Added tactile depth
                    shadowColor: Colors.black45,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      side: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                  label: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
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