import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profilescreen.dart';
import 'home.dart';
import 'AdminPanel.dart';

class LoginPage extends StatelessWidget {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  LoginPage({super.key});

  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bgg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.07)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/logo1.png',
                      height: isMobile ? 100 : 140,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: _boxStyle(),
                    child: TextField(
                      controller: emailController,
                      decoration: _inputStyle("Email", Icons.email),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: _boxStyle(),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputStyle("Password", Icons.lock),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot your password?",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 60 : 80,
                        vertical: isMobile ? 16 : 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                    child: Text(
                      "Login",
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Or login with",
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _SocialIcon(icon: Icons.g_mobiledata),
                      SizedBox(width: 16),
                      _SocialIcon(icon: Icons.apple),
                      SizedBox(width: 16),
                      _SocialIcon(icon: Icons.facebook),
                    ],
                  ),
                  const SizedBox(height: 25),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      "New user? Sign up",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showError(context, 'Email and password cannot be empty.');
      return;
    }

    if (!email.contains('@')) {
      showError(context, 'Please enter a valid email address.');
      return;
    }
    if (email == 'minahilsharif28@gmail.com' && password == '12345678') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AdminPanel()),
      );
      return;
    }

    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = authResult.user!.uid;

      // Step 1: Check in 'users' collection (for Chefs or both)
      final usersDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (usersDoc.exists) {
        final userData = usersDoc.data()!;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProfileScreen(
                  userId: uid,
                  restaurantName: userData['rname'] ?? '',
                  description: userData['description'] ?? '',
                  profileImageUrl: userData['profileImageUrl'] ?? '',
                ),
          ),
        );
        return;
      }

      // Step 2: Check in 'user' collection (for regular users)
      final userDoc =
          await FirebaseFirestore.instance.collection('user').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => FeedScreen(
                  profileImageUrl: userData['profileImageUrl'] ?? '',
                  userId:
                      userDoc
                          .id, // ✅ Use document ID instead of userData['uid']
                ),
          ),
        );
        return;
      }

      // Not found in either collection
      showError(context, 'User profile not found in database.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          showError(context, 'No user found for this email.');
          break;
        case 'wrong-password':
          showError(context, 'Incorrect password.');
          break;
        default:
          showError(context, 'Authentication error: ${e.message}');
      }
    } catch (e) {
      showError(context, 'Unexpected error: ${e.toString()}');
    }
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  BoxDecoration _boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;

  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: Icon(icon, color: Color(0xFF8B0000)),
    );
  }
}
