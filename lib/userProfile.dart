import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reel.dart';
import 'userchatlist.dart';
import 'SearchScreen.dart';

class UserProfileScreen extends StatefulWidget {
  final String profileImageUrl;
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.profileImageUrl,
    required this.userId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late String userName = '';
  late String profileImageUrl = '';
  bool isLoading = true;
  bool isDarkMode = false;

  int _currentIndex = 4;
  final Color deepRed = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('user')
            .doc(widget.userId)
            .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userName = data['name'] ?? 'User';
        profileImageUrl = data['profileImageUrl'] ?? '';
        isLoading = false;
      });
    }
  }

  Future<bool> hasNewMessages(String userId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: userId)
            .get();

    for (var doc in snapshot.docs) {
      final messagesSnapshot =
          await doc.reference
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (messagesSnapshot.docs.isNotEmpty) {
        final lastMessage = messagesSnapshot.docs.first;
        if (lastMessage['senderId'] != userId) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            deepRed.withOpacity(0.95),
                            deepRed.withOpacity(0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 56,
                              backgroundImage: NetworkImage(profileImageUrl),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ProfileButton(
                            label: 'Edit Profile',
                            onTap: () {
                              // Add navigation to EditProfile screen
                            },
                            backgroundColor: Colors.white,
                            textColor: deepRed,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Settings Row (Fixed here)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.logout, color: deepRed),
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    );
                                  }
                                },
                              ),
                              Text('Logout', style: TextStyle(color: deepRed)),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.dark_mode, color: deepRed),
                                onPressed: () {
                                  setState(() {
                                    isDarkMode = !isDarkMode;
                                  });
                                },
                              ),
                              Text(
                                isDarkMode ? 'Light Mode' : 'Dark Mode',
                                style: TextStyle(color: deepRed),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.fullscreen, color: deepRed),
                                onPressed: () {
                                  // Add fullscreen logic
                                },
                              ),
                              Text(
                                'Fullscreen',
                                style: TextStyle(color: deepRed),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TikTokScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => UChatListScreen(
                      currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    ),
              ),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(userId: widget.userId),
              ),
            );
          }
        },
        selectedItemColor: const Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_filled),
            label: "Reels",
          ),
          BottomNavigationBarItem(
            icon: FutureBuilder<bool>(
              future: hasNewMessages(widget.userId),
              builder: (context, snapshot) {
                bool showDot = snapshot.data == true;
                return Stack(
                  children: [
                    const Icon(Icons.message_outlined),
                    if (showDot)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon:
                widget.profileImageUrl.isNotEmpty
                    ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(widget.profileImageUrl),
                    )
                    : const Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  const _ProfileButton({
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
