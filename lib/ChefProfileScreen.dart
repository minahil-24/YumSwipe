import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatScreen.dart';
import 'reel.dart';
import 'userchatlist.dart';

class ChefProfileScreen extends StatefulWidget {
  final String currentUserId; // viewer
  final String chefId;
  final String restaurantName;
  final String description;
  final String profileImageUrl;

  const ChefProfileScreen({
    super.key,
    required this.currentUserId,
    required this.chefId,
    required this.restaurantName,
    required this.description,
    required this.profileImageUrl,
  });

  @override
  State<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends State<ChefProfileScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool isFollowing = false;

  bool _loading = true;
  int totalPosts = 0;
  int followerCount = 0;

  List<String> dishImages = [];
  List<String> videoUrls = [];
  List<VideoPlayerController> videoControllers = [];

  int _mediaTabIndex = 0; // 0 for images, 1 for videos

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final Color deepRed = const Color(0xFF8B0000);
  checkIfFollowing() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.chefId)
            .collection('followers')
            .doc(widget.currentUserId)
            .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchMedia();
    checkIfFollowing(); // ✅ Add this
    fetchFollowerCount(); // 👈 Add this
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.9,
      upperBound: 1.0,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> fetchFollowerCount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.chefId)
            .collection('followers')
            .get();

    setState(() {
      followerCount = snapshot.size; // 👈 .size gives total docs
    });
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
          return true; // 👈 Regular user sent a message
        }
      }
    }

    return false;
  }

  Future<void> fetchMedia() async {
    try {
      final dishesSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.chefId)
              .collection('dishes')
              .get();

      final videosSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.chefId)
              .collection('videos')
              .get();

      final List<String> dishUrls =
          dishesSnapshot.docs
              .map((doc) => doc['url'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

      final List<String> videoUrlsList =
          videosSnapshot.docs
              .map((doc) => doc['url'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

      for (var url in videoUrlsList) {
        final controller = VideoPlayerController.network(url);
        await controller.initialize();
        controller.setLooping(true);
        controller.setVolume(0.0);
        controller.play();
        videoControllers.add(controller);
      }

      setState(() {
        dishImages = dishUrls;
        videoUrls = videoUrlsList;
        totalPosts = dishImages.length + videoUrls.length;
        _loading = false;
      });
    } catch (e) {
      print('Error loading media: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in videoControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildMediaTabIcon(IconData icon, int index) {
    final bool selected = _mediaTabIndex == index;
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () => setState(() => _mediaTabIndex = index),
      child: ScaleTransition(
        scale: selected ? _scaleAnimation : AlwaysStoppedAnimation(1),
        child: Icon(
          icon,
          color: selected ? deepRed : Colors.grey,
          size: 32,
          shadows:
              selected
                  ? [
                    Shadow(
                      color: deepRed.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showImages = _mediaTabIndex == 0;
    final mediaCount = showImages ? dishImages.length : videoUrls.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [deepRed.withOpacity(0.95), deepRed.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.restaurantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: NetworkImage(widget.profileImageUrl),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 20),
                      _StatItem(label: 'Posts', count: '$totalPosts'),
                      const SizedBox(width: 40),
                      _StatItem(label: 'Followers', count: '$followerCount'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileButton(
                        label: isFollowing ? 'Following' : 'Follow',
                        onTap: () async {
                          final chefRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.chefId);
                          final currentUserRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.currentUserId);

                          if (isFollowing) {
                            // Unfollow: Remove both entries
                            await chefRef
                                .collection('followers')
                                .doc(widget.currentUserId)
                                .delete();
                            await currentUserRef
                                .collection('following')
                                .doc(widget.chefId)
                                .delete();
                          } else {
                            // Follow: Create both entries
                            await chefRef
                                .collection('followers')
                                .doc(widget.currentUserId)
                                .set({
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'followerId': widget.currentUserId,
                                });

                            await currentUserRef
                                .collection('following')
                                .doc(widget.chefId)
                                .set({
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'followedChefId': widget.chefId,
                                });
                          }

                          // Update UI
                          setState(() {
                            isFollowing = !isFollowing;
                          });
                        },
                        backgroundColor: Colors.white,
                        textColor: deepRed,
                      ),

                      const SizedBox(width: 16),
                      _ProfileButton(
                        label: 'Message',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ChatScreen(
                                    currentUserId: widget.currentUserId,
                                    receiverId: widget.chefId,
                                    receiverName: widget.restaurantName,
                                    receiverImage: widget.profileImageUrl,
                                  ),
                            ),
                          );
                        },
                        backgroundColor: Colors.white,
                        textColor: deepRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Media Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMediaTabIcon(Icons.grid_on, 0),
                const SizedBox(width: 60),
                _buildMediaTabIcon(Icons.videocam_outlined, 1),
              ],
            ),

            const SizedBox(height: 20),

            // Media Grid
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : mediaCount == 0
                      ? const Center(
                        child: Text(
                          'No bites yet',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          itemCount: mediaCount,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemBuilder: (context, index) {
                            if (showImages) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  dishImages[index],
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              final controller = videoControllers[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: VideoPlayer(controller),
                                ),
                              );
                            }
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 2) {
            // Navigate to Reels (TikTokScreen)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TikTokScreen()),
            );
          } else if (index == 3) {
            // index 3 is the "Messages" tab
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => UChatListScreen(
                      currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    ),
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
              future: hasNewMessages(widget.currentUserId),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String count;

  const _StatItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
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
