import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:redebugger/theme/theme.dart'; // AppTheme

class ContactAdminPage extends StatelessWidget {
  const ContactAdminPage({super.key});

  final String linkedInUrl =
      'https://www.linkedin.com/in/oluwadamilare-ojo-67996127b';
  final String githubUrl = 'https://github.com/moxie-15';
  final String whatsappUrl = 'https://wa.me/7066099313';
  final String emailUrl = 'mailto:samuelayomideojo9@gmail.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Contact Admin'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset('images/stu_back1.jpg', fit: BoxFit.cover),
          ),

          // Overlay with slight dark tint (optional for readability)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SizedBox(height: 20),
          // Center container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white, // solid container
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('images/admin.jpg'),
                      ),
                      const SizedBox(height: 20),

                      // Name & Role
                      const Text(
                        'Moxie',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Computer Engineering Student',
                        style: TextStyle(fontSize: 20, color: Colors.black54),
                      ),
                      const SizedBox(height: 30),

                      // Contact Icons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.linkedin),
                            color: Colors.blue,
                            iconSize: 32,
                            tooltip: 'LinkedIn',
                            onPressed: () => _launchUrl(linkedInUrl),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.github),
                            color: Colors.black,
                            iconSize: 32,
                            tooltip: 'GitHub',
                            onPressed: () => _launchUrl(githubUrl),
                          ),
                          const SizedBox(width: 20),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.whatsapp),
                            color: Colors.green,
                            iconSize: 32,
                            tooltip: 'WhatsApp',
                            onPressed: () => _launchUrl(whatsappUrl),
                          ),

                          const SizedBox(width: 20),
                          IconButton(
                            icon: const FaIcon(FontAwesomeIcons.envelope),
                            color: Colors.redAccent,
                            iconSize: 32,
                            tooltip: 'Email',
                            onPressed: () => _launchUrl(emailUrl),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Developer Details
                      const Text(
                        'Skills:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Flutter, Web3, AI, Blockchain',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
