import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'cbottomdrawer.dart';
import 'ChatListScreen.dart';
import 'chef_orders_screen.dart';
import 'CStoryViewScreen.dart';
import 'chatbot.dart';
import 'SearchScreen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final String restaurantName;
  final String description;
  final String profileImageUrl;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.restaurantName,
    required this.description,
    required this.profileImageUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 4; // Profile tab selected by default
  bool _loading = true;
  int totalPosts = 0;
  int followerCount = 0;
  int orderCount = 0;
  List<String> dishImages = [];
  List<String> videoUrls = [];
  List<String> dishIds = [];
  List<VideoPlayerController> videoControllers = [];

  int _mediaTabIndex = 0; // 0 for images, 1 for videos

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final Color deepRed = const Color(0xFF8B0000);
  final Color mustard = const Color(0xFFFFDB58); // Mustard color for border

  @override
  void initState() {
    super.initState();
    fetchMedia();
    fetchFollowerCount();
    fetchOrderCount();
    // 👈 Add this
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

  Future<void> fetchOrderCount() async {
    try {
      final ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where('chefId', isEqualTo: widget.userId)
              .get();

      setState(() {
        orderCount = ordersSnapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching order count: $e');
    }
  }

  Future<void> fetchFollowerCount() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('followers')
            .get();

    setState(() {
      followerCount = snapshot.size; // 👈 .size gives total docs
    });
  }

  Future<bool> hasNewMessages(String chefId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: chefId)
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
        if (lastMessage['senderId'] != chefId) {
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
              .doc(widget.userId)
              .collection('dishes')
              .get();

      final videosSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('videos')
              .get();

      final List<String> dishUrls =
          dishesSnapshot.docs
              .map((doc) => doc['url'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
      final List<String> dishDocIds =
          dishesSnapshot.docs.map((doc) => doc.id).toList();

      final List<String> videoUrlsList =
          videosSnapshot.docs
              .map((doc) => doc['url'] as String? ?? '')
              .where((url) => url.isNotEmpty)
              .toList();

      // Initialize video controllers
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
        dishIds = dishDocIds;
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

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChefOrdersScreen(chefId: widget.userId),
        ),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SearchScreen(userId: widget.userId)),
      );
    } else if (index == 2) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) => const cBottomDrawer(),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatListScreen(currentUserId: widget.userId),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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

  Widget _buildProfileNavIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.red.shade300, // light red border, always visible
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 14,
        backgroundImage: NetworkImage(widget.profileImageUrl),
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      deepRed.withOpacity(0.95),
                      deepRed.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: deepRed.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
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
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Here is the updated CircleAvatar with mustard border:
                    GestureDetector(
                      onTap: () async {
                        final stories =
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId) // make sure you pass this
                                .collection('stories')
                                .limit(1)
                                .get();

                        if (stories.docs.isNotEmpty) {
                          final storyId = stories.docs.first.id;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CStoryViewScreen(
                                    chefId: widget.userId,
                                    storyId: storyId,
                                  ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 200, 255, 50),
                            width: 6,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 58,
                          backgroundColor: const Color(0xFF8B0000),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundImage: NetworkImage(
                              widget.profileImageUrl,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatItem(
                          label: 'Posts',
                          count: '$totalPosts',
                          color: Colors.white,
                        ),
                        const SizedBox(width: 47),
                        _StatItem(
                          label: 'Followers',
                          count: '$followerCount',
                          color: Colors.white,
                        ),

                        const SizedBox(width: 44),
                        _StatItem(
                          label: 'Orders',
                          count: '$orderCount',
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ProfileButton(
                            label: 'Edit Profile',
                            onTap: () {},
                            backgroundColor: Colors.white,
                            textColor: deepRed,
                          ),
                          const SizedBox(width: 18),
                          _ProfileButton(
                            label: 'Share Profile',
                            onTap: () {},
                            backgroundColor: Colors.white,
                            textColor: deepRed,
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => YumSwipeChatbotApp(),
                                ),
                              );
                            },
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/chat_bg.png',
                              ), // AI avatar
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 38),

              // Media Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMediaTabIcon(Icons.grid_on, 0),
                  const SizedBox(width: 60),
                  _buildMediaTabIcon(Icons.shopping_bag_outlined, 1),
                  const SizedBox(width: 60),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChefOrdersScreen(chefId: widget.userId),
                        ),
                      );
                    },
                    child: Icon(Icons.receipt_long, color: deepRed, size: 32),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              if (_loading)
                const CircularProgressIndicator(color: Color(0xFF8B0000))
              else if (mediaCount == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    'No bites yet',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child:
                      showImages
                          ? GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: dishImages.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (_) => Dialog(
                                          backgroundColor: Colors.black
                                              .withOpacity(0.8),
                                          insetPadding: const EdgeInsets.all(
                                            20,
                                          ),
                                          child: Stack(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: Image.network(
                                                  dishImages[index],
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: 30,
                                                  ),
                                                  onPressed: () async {
                                                    final confirm = await showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            context,
                                                          ) => AlertDialog(
                                                            title: const Text(
                                                              'Delete Dish',
                                                            ),
                                                            content: const Text(
                                                              'Are you sure you want to delete this dish?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              TextButton(
                                                                onPressed:
                                                                    () => Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Delete',
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                    );

                                                    if (confirm == true) {
                                                      final dishId =
                                                          dishIds[index];
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('users')
                                                          .doc(widget.userId)
                                                          .collection('dishes')
                                                          .doc(dishId)
                                                          .delete();

                                                      setState(() {
                                                        dishImages.removeAt(
                                                          index,
                                                        );
                                                        dishIds.removeAt(index);
                                                        totalPosts--;
                                                      });

                                                      Navigator.pop(
                                                        context,
                                                      ); // Close the image dialog
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    dishImages[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          )
                          : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: videoUrls.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                            itemBuilder: (context, index) {
                              final controller = videoControllers[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AspectRatio(
                                  aspectRatio: controller.value.aspectRatio,
                                  child: VideoPlayer(controller),
                                ),
                              );
                            },
                          ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: 'Home',
            activeIcon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: deepRed, width: 2),
              ),
              child: const Icon(Icons.home),
            ),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            label: 'Search',
            activeIcon: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: deepRed, width: 2),
              ),
              child: const Icon(Icons.search),
            ),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Add',
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
            icon: _buildProfileNavIcon(),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: color,
            shadows: [
              Shadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: color.withOpacity(0.8),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
    );
  }
}
