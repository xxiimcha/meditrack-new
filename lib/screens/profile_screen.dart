import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_bottom_navbar.dart';
import '../widgets/dialog.dart'; // Import dialogs

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved session data

    // Navigate to login screen and clear navigation stack
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const CustomBottomNavBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Medications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    _buildOptionTile(Icons.favorite_border, "Current Medications", context, onTap: () {
                      Navigator.pushNamed(context, '/current_medications');
                    }),
                    _buildOptionTile(Icons.check_circle_outline, "Record Intake", context, onTap: () {
                      Navigator.pushNamed(context, '/record_intake');
                    }),
                    const Divider(),
                    _buildOptionTile(Icons.folder_open, "Help", context, onTap: () => HelpDialogBox.show(context)),
                    _buildOptionTile(Icons.info_outline, "About", context, onTap: () => AboutDialogBox.show(context)),
                    _buildOptionTile(Icons.logout, "Logout", context, onTap: () => _logout(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, BuildContext context,
      {bool selected = false, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.green.shade200 : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: onTap ?? () {},
      ),
    );
  }
}
