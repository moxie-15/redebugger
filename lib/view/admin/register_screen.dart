import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedClass;
  String? _selectedStream;
  final Map<String, List<String>> _classStreams = {
    "JSS 1": [],
    "JSS 2": [],
    "JSS 3": [],
    "SSS 1": ["Science", "Arts", "Commercial"],
    "SSS 2": ["Science", "Arts", "Commercial"],
    "SSS 3": ["Science", "Arts", "Commercial"],
  };

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Replace with your Firebase Web API Key
  final String apiKey = "AIzaSyBUhX2E0By8SVENql5mF4KvQR_uH6yPamQ";

  /// Register new user
  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "returnSecureToken": true,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data["error"]["message"] ?? "Registration failed");
      }

      final uid = data['localId'];

      // Create or update Firestore user document
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(), // keep track of login
        'displayName': _selectedRole == 'student' ? _nameController.text.trim() : "",
        'studentClass': _selectedRole == 'student' ? _selectedClass : null,
        'studentStream': _selectedRole == 'student' ? _selectedStream : null,
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User created successfully 🎉")),
      );

      _emailController.clear();
      _passwordController.clear();
      setState(() => _selectedRole = 'student');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
        backgroundColor: const Color.fromARGB(255, 7, 7, 123),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/reaal.jpg'),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'CREATE USER',
                        style: TextStyle(
                          color: Color.fromARGB(255, 2, 2, 104),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(
                        color: Color.fromARGB(255, 2, 2, 104),
                        thickness: 2,
                      ),
                      const SizedBox(height: 20),

                      /// Email field
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          } else if (!RegExp(
                            r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      /// Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      /// Role dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'teacher',
                            child: Text('Teacher'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Role',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),

                      /// Extra Fields for Student
                      if (_selectedRole == 'student') ...[
                        TextFormField(
                          controller: _nameController,
                          validator: (value) {
                            if (_selectedRole == 'student' && (value == null || value.trim().isEmpty)) {
                              return 'Please enter the student\'s full name';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          hint: const Text("Select Class"),
                          items: _classStreams.keys
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClass = val;
                              _selectedStream = null;
                            });
                          },
                          validator: (value) {
                            if (_selectedRole == 'student' && value == null) {
                              return 'Select a class';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.school_outlined),
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (_selectedClass != null && _classStreams[_selectedClass]!.isNotEmpty) ...[
                          DropdownButtonFormField<String>(
                            value: _selectedStream,
                            hint: const Text("Select Stream"),
                            items: _classStreams[_selectedClass]!
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedStream = val),
                            validator: (value) {
                              if (_selectedRole == 'student' && _classStreams[_selectedClass]!.isNotEmpty && value == null) {
                                return 'Select a stream';
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ],
                      const SizedBox(height: 10),

                      /// Submit button
                      GestureDetector(
                        onTap: _isLoading ? null : _createUser,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF001F3F),
                                Color.fromARGB(255, 5, 2, 27),
                                Color.fromARGB(255, 2, 2, 104),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.topRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text(
                                    'CREATE USER',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
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
      ),
    );
  }
}
