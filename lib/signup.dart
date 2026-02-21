import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chef_details_screen.dart';
import 'user_detail_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final typeList = ['User', 'Chef'];
  String selectedType = 'User';
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  DateTime? birthDate;

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => birthDate = date);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background image
          Positioned.fill(
            child: Image.asset('assets/bgg.jpg', fit: BoxFit.cover),
          ),
          // 🌓 Dark overlay
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.07)),
          ),
          // ✨ Main content
          Center(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'logo',
                      child: Image.asset(
                        'assets/logo1.png',
                        height: isMobile ? 80 : 100,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    _buildTextField("Email", controller: emailController),
                    _buildTextField(
                      "Password",
                      controller: passwordController,
                      obscure: true,
                    ),
                    GestureDetector(
                      onTap: _pickBirthDate,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: _boxStyle(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              birthDate == null
                                  ? 'Select Birthdate'
                                  : birthDate!.toLocal().toString().split(
                                    ' ',
                                  )[0],
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF8B0000),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedType == 'Chef' || selectedType == 'Both') {
                          Navigator.of(context).push(
                            _createRoute(
                              ChefDetailsScreen(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                birthDate: birthDate,
                              ),
                            ),
                          );
                        } else if (selectedType == 'User') {
                          Navigator.of(context).push(
                            _createRoute(
                              UserDetailsScreen(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                                birthDate: birthDate,
                              ),
                            ),
                          );
                        } else {
                          _signupUser(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        'Signup',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Or signup with",
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
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    bool obscure = false,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: _boxStyle(),
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(
            hint == "Email" ? Icons.email : Icons.lock,
            color: Colors.grey[600],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: _boxStyle(),
      margin: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selectedType,
        items:
            typeList.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
        onChanged: (value) => setState(() => selectedType = value!),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  BoxDecoration _boxStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }

  void _signupUser(BuildContext context) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'type': selectedType,
            'email': emailController.text.trim(),
            'birthDate': birthDate?.toIso8601String(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup successful!")));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Signup failed: ${e.toString()}")));
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero);
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Icon(icon, color: Color(0xFF8B0000)),
    );
  }
}
