import 'package:flutter/material.dart';
import 'package:redebugger/settings/system_setting.dart';

import 'package:redebugger/theme/theme.dart';
import 'package:redebugger/view/admin/add_quiz_screen.dart';
import 'package:redebugger/view/admin/admin_quiz_selection_screen.dart';


class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    TeacherDashboardPage(),
    ManageExamsPage(),
    ResultsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teacher Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF001F3F),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF001F3F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Manage Exams",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Manage Student Data",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

/// --- Dashboard Page ---
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            "Welcome to Teacher Dashboard",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: 5, // Windows-friendly
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildCard(
                icon: Icons.assignment,
                title: "Create Exam",
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddQuizScreen()),
                  );
                },
              ),
              _buildCard(
                icon: Icons.group,
                title: "Manage Students",
                color: Colors.green,
                onTap: () {},
              ),
              _buildCard(
                icon: Icons.school,
                title: "Class Reports",
                color: Colors.orange,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      color: color.withOpacity(0.9),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- Manage Exams Page ---
class ManageExamsPage extends StatelessWidget {
  const ManageExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 5, // Windows-friendly
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildClassCard(
          icon: Icons.assignment,
          title: "Create Exam",
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddQuizScreen()),
            );
          },
        ),
      ],
    );
  }
}

Widget _buildClassCard({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 5,
    color: color.withOpacity(0.9),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// --- Results Page ---
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 5, // Windows-friendly
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: [
        _buildResultCard(
          icon: Icons.assignment,
          title: "View Student Result",
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminQuizSelectionScreen(),
              ),
            );
          },
        ),
        _buildResultCard(
          icon: Icons.school,
          title: "Class Reports",
          color: Colors.orange,
          onTap: () {},
        ),
      ],
    );
  }
}

Widget _buildResultCard({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 5,
    color: color.withOpacity(0.9),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// --- Profile Page ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(350, 80, 350, 80),
      child: Container(
        padding: const EdgeInsets.all(50), // inner spacing inside the container
        decoration: BoxDecoration(
          color: Colors.white, // background color
          borderRadius: BorderRadius.circular(20), // rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Name
            const Text(
              "John Doe",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Email
            const Text(
              "johndoe@email.com",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Profile Options
        
            _buildProfileOption(
              icon: Icons.settings,
              title: "Settings",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SystemSettingsScreen()),
                );
              },
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildProfileOption({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  required Color color,
}) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}
