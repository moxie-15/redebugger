import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AuthService {
  final String apiKey =
      "AIzaSyBUhX2E0By8SVENql5mF4KvQR_uH6yPamQ"; // Firebase API Key
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// -----------------------
  /// Create/Update Firestore Doc
  /// -----------------------
  Future<void> createOrUpdateUserDoc(
    String uid,
    String email,
    String role,
  ) async {
    final userDoc = _firestore.collection('users').doc(uid);

    await userDoc.set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
  }

  /// -----------------------
  /// SIGN IN USER
  /// -----------------------
  Future<Map<String, dynamic>> signIn(
    String email,
    String password,
    String selectedRole,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineKey = 'offline_auth_${email.toLowerCase()}';

    try {
      final url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey",
      );

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "returnSecureToken": true,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error["error"]["message"]);
      }

      final data = jsonDecode(response.body);
      final uid = data['localId'];

      // 🔑 Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception("User record not found.");
      }

      final role = userDoc.data()!['role'] as String;

      // 🚨 Role mismatch check
      if (role != selectedRole) {
        throw Exception("Role mismatch! You are registered as $role");
      }

      // ✅ Cache credentials offline for Hybrid mode
      final offlinePayload = {
         "uid": uid,
         "email": email,
         "role": role,
         "hash": password.hashCode.toString(), // Basic deterministic hash for offline check
      };
      await prefs.setString(offlineKey, jsonEncode(offlinePayload));

      // ✅ Update last login
      await createOrUpdateUserDoc(uid, email, role);

      return {
        "uid": uid,
        "email": data['email'],
        "idToken": data['idToken'],
        "role": role,
      };
    } catch (e) {
      if (e is SocketException || e.toString().contains("Failed host lookup") || e.toString().contains("Connection refused")) {
         // INTERCEPTED OFFLINE MODE! 
         if (prefs.containsKey(offlineKey)) {
            final Map<String, dynamic> cached = jsonDecode(prefs.getString(offlineKey)!);
            if (cached['hash'] == password.hashCode.toString() && cached['role'] == selectedRole) {
                return {
                  "uid": cached['uid'],
                  "email": cached['email'],
                  "idToken": "OFFLINE_TOKEN_${DateTime.now().millisecondsSinceEpoch}",
                  "role": cached['role'],
                };
            } else {
                throw Exception("Offline Login Failed: Incorrect Password or Role.");
            }
         } else {
            throw Exception("No offline profile found. Please connect to the internet to log in for the first time.");
         }
      }
      rethrow;
    }
  }

  /// -----------------------
  /// REGISTER USER
  /// -----------------------
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
        "returnSecureToken": true,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error["error"]["message"]);
    }

    final data = jsonDecode(response.body);
    final uid = data['localId'];

    // 🔑 Save role in Firestore
    await createOrUpdateUserDoc(uid, email, role);

    return {"uid": uid, "email": email, "role": role};
  }

  /// -----------------------
  /// ROUTE USER BASED ON ROLE
  /// -----------------------
  void routeUser(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        Navigator.pushReplacementNamed(context, '/adminHome');
        break;
      case 'teacher':
        Navigator.pushReplacementNamed(context, '/teacherHome');
        break;
      case 'student':
        Navigator.pushReplacementNamed(context, '/studentDashboard');
        break;
      default:
        throw Exception("Unknown user role");
    }
  }

  /// -----------------------
  /// RESET PASSWORD
  /// -----------------------
  Future<void> resetPassword(String email) async {
    final url = Uri.parse(
      "https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"requestType": "PASSWORD_RESET", "email": email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error["error"]["message"]);
    }
  }

  /// -----------------------
  /// SIGN OUT
  /// -----------------------
  Future<void> signOut(BuildContext context) async {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
