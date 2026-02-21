import 'package:flutter/material.dart';
import 'package:flutter_application_1/DropDishScreen.dart' as dishScreen;
import 'package:flutter_application_1/DropVideoScreen.dart' as videoScreen;
import 'StoryUploadScreen.dart';

class cBottomDrawer extends StatelessWidget {
  const cBottomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      height: 250,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _DrawerOption(
              icon: Icons.fastfood,
              label: "Dish Drop",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const dishScreen.DropDishScreen(),
                  ),
                );
              },
            ),
            _DrawerOption(
              icon: Icons.video_call,
              label: "Food Flick",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const videoScreen.DropDishScreen(),
                  ),
                );
              },
            ),
            _DrawerOption(
              icon: Icons.local_fire_department,
              label: "Spice Story",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StoryUploadScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF8B0000)),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
