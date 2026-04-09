import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:redebugger/model/category.dart';
import 'package:redebugger/student/quiz_grid_screen.dart';
import 'package:redebugger/student/student_dashboard.dart';

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailCtrl = TextEditingController(
    text: "student@ghope.com",
  );
  final TextEditingController _passwordCtrl = TextEditingController(
    text: "example1",
  );
  final TextEditingController _nameCtrl = TextEditingController(
    text: "John Doe",
  );

  String? _selectedClass;
  String? _selectedStream;
  final Map<String, List<String>> _classStreams = {
    "JSS 1": [],
    "JSS 2": [],
    "JSS 3": [],
    "SSS 1": [],
    "SSS 2": ["Science", "Arts", "Commercial"],
    "SSS 3": ["Science", "Arts", "Commercial"],
  };

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _signIn() async {
    if (_selectedClass == null ||
        _nameCtrl.text.isEmpty ||
        (_classStreams[_selectedClass]?.isNotEmpty == true &&
            _selectedStream == null)) {
      setState(
        () => _error =
            "Please enter your name and select your class${_classStreams[_selectedClass]?.isNotEmpty == true ? ' and stream' : ''}.",
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = _auth.currentUser;
      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDashboard(
              studentName: _nameCtrl.text.trim(),
              studentClass:
                  _selectedClass! +
                  (_selectedStream != null ? " ($_selectedStream)" : ""),
            ),
          ),
          (route) => false, // removes all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "Login failed.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streams = _selectedClass != null
        ? _classStreams[_selectedClass]!
        : [];

    return Scaffold(
      body: Stack(
        children: [
          // 1. The core UI payload
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/reaal.jpg'), // <-- Your background image
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'REGISTER FOR THE EXAM',
                          style: TextStyle(
                            color: Color.fromARGB(255, 2, 2, 104),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(
                          color: Color.fromARGB(255, 2, 2, 104),
                          thickness: 2,
                        ),
                        const SizedBox(height: 15),

                        // Name
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Class
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClass,
                          hint: const Text("Select your class"),
                          items: _classStreams.keys
                              .map(
                                (c) => DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClass = val;
                              _selectedStream = null;
                            });
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Stream
                        if (streams.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedStream,
                            hint: const Text("Select your stream"),
                            items: streams
                                .map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedStream = val),
                          ),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Error
                        if (_error != null)
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),

                        // Register Button
                        GestureDetector(
                          onTap: _loading ? null : _signIn,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF001F3F),
                                  Color.fromARGB(255, 2, 2, 104),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.topRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'REGISTER',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. The Dev-Only Escape Hatch (Back Button)
          // Make sure you delete this specific Positioned block before prod!
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), // Makes it visible against light/dark backgrounds
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}