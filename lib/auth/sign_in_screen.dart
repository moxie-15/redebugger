import 'package:flutter/material.dart';
import 'package:redebugger/auth/auth_service.dart';
import 'package:redebugger/model/faqs_screen.dart';
import 'package:redebugger/pages/contact_admin_page.dart';
import 'package:redebugger/student/student_home_screen.dart';
import 'package:redebugger/teacher/teacher_home_screen.dart';
import 'package:redebugger/view/admin/admin_home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

  String? selectedRole;
  final List<String> roles = ['student', 'teacher', 'admin'];

  final AuthService _authService = AuthService();

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRole == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a roleee⚡")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // Pass selectedRole to signIn
      final data = await _authService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
        selectedRole!,
      );

      final role = data['role'];

      Widget destination;
      if (role == 'student') {
        destination = const StudentHomeScreen();
      } else if (role == 'teacher') {
        destination = const TeacherHomeScreen();
      } else if (role == 'admin') {
        destination = const AdminHomeScreen();
      } else {
        throw Exception("Unknown role ❓ Reach out to School Admin for logs");
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Successful 🎉"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 7, 7, 123),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/reaals.jpg'),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Color.fromARGB(255, 2, 2, 104),
                            fontSize: 33,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(
                        color: Color.fromARGB(255, 2, 2, 104),
                        thickness: 2,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: emailController,
                        validator: (value) => value == null || value.isEmpty
                            ? "Please Enter Email"
                            : null,
                        decoration: const InputDecoration(
                          hintText: "Enter Email",
                          suffixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        validator: (value) => value == null || value.isEmpty
                            ? "Please Enter Password"
                            : null,
                        decoration: InputDecoration(
                          hintText: "Enter Password",
                          border: const OutlineInputBorder(),
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
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Select Role',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        hint: const Text("Choose role"),
                        items: roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedRole = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                        validator: (value) =>
                            value == null ? "Please select a role" : null,
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: isLoading ? null : login,
                        child: Container(
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
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                        color: Color.fromARGB(255, 2, 2, 104),
                        thickness: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "faqs",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaqsScreen()),
              );
            },
            icon: const Icon(Icons.help_outline),
            label: const Text("FAQs"),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: "contact_admin",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactAdminPage()),
              );
            },
            icon: const Icon(Icons.message),
            label: const Text("Contact Admin"),
          ),
        ],
      ),
    );
  }
}
