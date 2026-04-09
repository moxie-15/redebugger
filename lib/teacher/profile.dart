import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            "John Doe", // Replace with dynamic teacher name
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "johndoe@email.com", // Replace with dynamic email
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildProfileOption(
            icon: Icons.edit,
            title: "Edit Profile",
            onTap: () {
              // TODO: Navigate to Edit Profile Page
            },
          ),
          _buildProfileOption(
            icon: Icons.lock,
            title: "Change Password",
            onTap: () {
              // TODO: Navigate to Change Password Page
            },
          ),
          _buildProfileOption(
            icon: Icons.logout,
            title: "Log Out",
            onTap: () {
              // TODO: Implement logout logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
