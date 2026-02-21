import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'cloudinary_service.dart';
import 'email_service.dart';

class UserDetailsScreen extends StatefulWidget {
  final String email, password;
  final DateTime? birthDate;

  const UserDetailsScreen({
    super.key,
    required this.email,
    required this.password,
    required this.birthDate,
  });

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  File? _profileImage;
  Uint8List? _webImageBytes;

  String? _selectedCity;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _pakistanCities = [
    {"name": "Karachi", "lat": 24.8607, "lng": 67.0011},
    {"name": "Lahore", "lat": 31.5497, "lng": 74.3436},
    {"name": "Islamabad", "lat": 33.6844, "lng": 73.0479},
    {"name": "Rawalpindi", "lat": 33.5651, "lng": 73.0169},
    {"name": "Peshawar", "lat": 34.015, "lng": 71.5805},
    {"name": "Quetta", "lat": 30.1798, "lng": 66.975},
    {"name": "Multan", "lat": 30.1575, "lng": 71.5249},
    {"name": "Faisalabad", "lat": 31.4504, "lng": 73.135},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: TextStyle(color: Colors.grey[600]),
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _profileImage = null;
        });
      } else {
        setState(() {
          _profileImage = File(pickedFile.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _completeSignup() async {
    if (usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your username")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );

      await userCredential.user!.sendEmailVerification();
      await sendConfirmationEmail(widget.email, usernameController.text.trim());

      String imageUrl = "";
      if (_profileImage != null || _webImageBytes != null) {
        imageUrl =
            await CloudinaryService.uploadImage(
              file: _profileImage,
              bytes: _webImageBytes,
              fileName: "${widget.email}_profile.jpg",
            ) ??
            "";
      }

      await FirebaseFirestore.instance
          .collection('user') // Store in 'user' collection
          .doc(userCredential.user!.uid)
          .set({
            'username': usernameController.text.trim(),
            'email': widget.email,
            'birthDate': widget.birthDate,
            'selectedCity': _selectedCity,
            'profileImageUrl': imageUrl,
            'type': 'User',
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup complete! Please verify your email."),
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushNamed(context, '/login');
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Signup failed: ${e.message}")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _imagePreview() {
    if (_profileImage != null) {
      return ClipOval(
        child: Image.file(
          _profileImage!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
        ),
      );
    }
    if (_webImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _webImageBytes!,
          width: 130,
          height: 130,
          fit: BoxFit.cover,
        ),
      );
    }
    return const CircleAvatar(
      radius: 65,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 80, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bgg.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.07)),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _imagePreview(),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF8B0000),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Username field
                  Container(
                    decoration: _boxStyle(),
                    child: TextField(
                      controller: usernameController,
                      decoration: _inputStyle(
                        "Enter your username",
                        Icons.person,
                      ),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // City Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: "Select City",
                      labelStyle: const TextStyle(color: Colors.black87),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFF8B0000),
                          width: 2,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF8B0000),
                    ),
                    items:
                        _pakistanCities
                            .map(
                              (city) => DropdownMenuItem<String>(
                                value: city['name'],
                                child: Text(
                                  city['name'],
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _selectedCity = value),
                  ),
                  const SizedBox(height: 40),

                  _isLoading
                      ? const Center(
                        child: SpinKitFadingCircle(
                          color: Color(0xFF8B0000),
                          size: 60.0,
                        ),
                      )
                      : ElevatedButton(
                        onPressed: _completeSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          "Complete Signup",
                          style: TextStyle(
                            color: Color(0xFF8B0000),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
}
