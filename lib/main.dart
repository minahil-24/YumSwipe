import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:flutter_application_1/chatbot.dart';

import 'Welcome_page.dart';
import 'login.dart';
import 'signup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBhq81MTHXC4zR5NUt7CfGKosabbyK-7EA",
      authDomain: "yumswipe.firebaseapp.com",
      projectId: "yumswipe",
      storageBucket: "yumswipe.appspot.com", // corrected!
      messagingSenderId: "1054522877458",
      appId: "1:1054522877458:web:41e7a337fa027910671acb",
      measurementId: "G-QX39KSS9B9",
    ),
  );

  runApp(const YumSwipeApp());
}

class YumSwipeApp extends StatelessWidget {
  const YumSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YUMSWIPE',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',

      routes: {
        '/': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => const SignupScreen(),
        //'/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
