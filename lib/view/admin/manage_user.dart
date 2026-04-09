import 'package:flutter/material.dart';
import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/delete_user.dart';
import 'package:redebugger/view/admin/register_screen.dart';

class ManageUser extends StatefulWidget {
  const ManageUser({super.key});

  @override
  State<ManageUser> createState() => _ManageUserState();
}

class _ManageUserState extends State<ManageUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.buttonColor,
        title: const Text("Manage user"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Expanded(
              // <-- so grid takes available space
              child: GridView(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // each card max width = 200px
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 20,
                ),
                children: [
                  _buildDashboardCard('Register User', Icons.person_add, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  }),
                  _buildDashboardCard('Delete User', Icons.person_remove, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeleteUserScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper widget builder
Widget _buildDashboardCard(String title, IconData icon, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    child: Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryColor),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ),
  );
}
