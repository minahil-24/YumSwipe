import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatScreen.dart';
import 'ChefProfileScreen.dart';
import 'userchatlist.dart';
import 'reel.dart';
import 'CartScreen.dart';
import 'orderscreen.dart';
import 'SearchScreen.dart';
import 'StoryViewScreen.dart';
import 'userProfile.dart';
import 'chatbot.dart';

class FeedScreen extends StatefulWidget {
  final String profileImageUrl;
  final String userId; // ✅ Add this line

  const FeedScreen({
    super.key,
    required this.profileImageUrl,
    required this.userId, // ✅ Add this line
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _currentIndex = 0;
  String? profileImageUrl;

  final firestore = FirebaseFirestore.instance;
  Set<String> cartDishIds = {}; // To track cart status

  @override
  void initState() {
    super.initState();
    fetchProfileImage();
  }

  // Fetch existing cart items to manage tick buttons
  Future<void> fetchCartItems() async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final cartDocs =
        await FirebaseFirestore.instance
            .collection('user') // Regular user collection
            .doc(currentUserId)
            .collection('cart')
            .get();

    setState(() {
      cartDishIds = cartDocs.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<List<DocumentSnapshot>> _getChefsWithStories() async {
    final firestore = FirebaseFirestore.instance;

    final chefs =
        await firestore
            .collection('users')
            .where('type', isEqualTo: 'Chef')
            .get();

    final results = await Future.wait(
      chefs.docs.map((chef) async {
        final storiesSnap =
            await chef.reference.collection('stories').limit(1).get();
        if (storiesSnap.docs.isNotEmpty) {
          return chef;
        }
        return null;
      }),
    );

    // Remove nulls
    return results.whereType<DocumentSnapshot>().toList();
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

  Future<void> fetchProfileImage() async {
    final userDocs = await firestore.collection('users').get();
    if (userDocs.docs.isNotEmpty) {
      setState(() {
        profileImageUrl = userDocs.docs.first['profileImageUrl'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: Colors.white,
            floating: true,
            pinned: true,
            elevation: 1,
            toolbarHeight: 100,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      color: const Color(0xFF8B0000),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),

                    const SizedBox(width: 10),
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
            ),
          ),

          // Story Section
          SliverToBoxAdapter(
            child: FutureBuilder<List<DocumentSnapshot>>(
              future: _getChefsWithStories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chefsWithStories = snapshot.data!;
                return SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: chefsWithStories.length,
                    itemBuilder: (context, index) {
                      final userDoc = chefsWithStories[index];
                      final chefId =
                          userDoc
                              .id; // ✅ Proper chef ID from 'users' collection
                      final chefData = userDoc.data() as Map<String, dynamic>;

                      final chefName = chefData['rname'] ?? 'Chef';
                      final profileImageUrl = chefData['profileImageUrl'];
                      final description = chefData['description'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                try {
                                  print(
                                    '🍽️ Loading stories for chefId: $chefId',
                                  );

                                  if (chefId.isEmpty) {
                                    print('❌ chefId is empty!');
                                    return;
                                  }

                                  final storiesSnap =
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(chefId)
                                          .collection('stories')
                                          .orderBy(
                                            'createdAt',
                                            descending: false,
                                          )
                                          .get();

                                  print(
                                    '✅ Fetched ${storiesSnap.docs.length} stories',
                                  );

                                  final storiesList =
                                      storiesSnap.docs.map((doc) {
                                        print(
                                          '📦 Story doc ID: ${doc.id}, URL: ${doc['url']}',
                                        );
                                        return {
                                          'id': doc.id,
                                          'url': doc['url'],
                                        };
                                      }).toList();

                                  if (storiesList.isEmpty) {
                                    print(
                                      '⚠️ No stories found for chefId: $chefId',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('No stories available.'),
                                      ),
                                    );
                                    return;
                                  }

                                  print('🧭 Building StoryViewScreen with:');
                                  print('  👉 chefId: $chefId');
                                  print(
                                    '  👉 stories count: ${storiesList.length}',
                                  );
                                  print('  👉 first story: ${storiesList[0]}');

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => StoryViewScreen(
                                            chefId: chefId,
                                            stories: storiesList,
                                            initialIndex: 0,
                                            chefName: chefName,
                                            profileImageUrl: profileImageUrl,
                                          ),
                                    ),
                                  );
                                } catch (e, stackTrace) {
                                  print('❌ Error loading stories: $e');
                                  print('🧵 StackTrace:\n$stackTrace');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error loading stories: $e',
                                      ),
                                    ),
                                  );
                                }
                              },

                              onDoubleTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ChefProfileScreen(
                                          currentUserId: widget.userId,
                                          chefId:
                                              chefId, // ✅ Properly passed chefId
                                          restaurantName: chefName,
                                          description: description,
                                          profileImageUrl: profileImageUrl,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF8B0000),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(
                                    profileImageUrl,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              chefName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchAllChefPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data!;
                return Column(
                  children: posts.map((post) => buildPostCard(post)).toList(),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar with 5 items
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
          } else if (index == 1) {
            //Navigate to Search full-screen image screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(userId: widget.userId),
              ),
            );
          } else if (index == 4) {
            //Navigate to Search full-screen image screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => UserProfileScreen(
                      userId: widget.userId,
                      profileImageUrl: widget.profileImageUrl,
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

  Widget buildPostCard(Map<String, dynamic> post) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final dishId = post['dishId'] ?? post['url']; // or some unique field
    final isInCart = cartDishIds.contains(dishId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ChefProfileScreen(
                        currentUserId: widget.userId,
                        chefId: post['chefId'], // from post map
                        restaurantName: post['rname'] ?? 'Chef', // chef name
                        description: post['description'] ?? '', // chef bio
                        profileImageUrl:
                            post['profileImageUrl'] ?? '', // profile image
                      ),
                ),
              );
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(post['profileImageUrl'] ?? ''),
            ),
          ),

          title: Text(
            post['rname'] ?? 'Chef',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(post['city'] ?? 'Location'),
          trailing: const Icon(Icons.more_vert),
        ),
        if (post['url'] != null)
          Image.network(post['url'], fit: BoxFit.cover, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            post['name'] ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ✅ ADD TO CART BUTTON
              ElevatedButton.icon(
                onPressed:
                    isInCart
                        ? null
                        : () async {
                          final cartRef = FirebaseFirestore.instance
                              .collection('user') // regular user
                              .doc(currentUserId)
                              .collection('cart')
                              .doc(dishId);

                          await cartRef.set({
                            'dishName': post['name'],
                            'imageUrl': post['url'],
                            'price': post['price'] ?? 0,
                            'chefId': post['chefId'],
                            'quantity': 1,
                          });

                          setState(() {
                            cartDishIds.add(dishId);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dish added to cart'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                icon: Icon(
                  isInCart ? Icons.check : Icons.shopping_cart,
                  color: const Color(0xFF8B0000),
                ),
                label: const Text(""),
              ),

              // ✅ ORDER BUTTON
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderScreen(dishData: post),
                    ),
                  );
                },
                icon: const Icon(Icons.delivery_dining),
                label: const Text("Order"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                ),
              ),

              // ✅ MESSAGE BUTTON
              IconButton(
                icon: const Icon(Icons.message, color: Color(0xFF8B0000)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatScreen(
                            currentUserId: currentUserId,
                            receiverId: post['chefId'],
                            receiverName: post['rname'],
                            receiverImage: post['profileImageUrl'],
                          ),
                    ),
                  );
                },
              ),

              // ✅ FOLLOW BUTTON
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChefProfileScreen(
                            currentUserId: widget.userId,
                            chefId: post['chefId'], // from post map
                            restaurantName:
                                post['rname'] ?? 'Chef', // chef name
                            description: post['description'] ?? '', // chef bio
                            profileImageUrl:
                                post['profileImageUrl'] ?? '', // profile image
                          ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B0000)),
                ),
                child: const Text(
                  "Follow",
                  style: TextStyle(color: Color(0xFF8B0000)),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllChefPosts() async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> allPosts = [];

    final chefDocs =
        await firestore
            .collection('users')
            .where('type', isEqualTo: 'Chef')
            .get();

    final postFutures = chefDocs.docs.map((chef) async {
      final chefData = chef.data();
      final chefId = chef.id;

      final dishSnap = await chef.reference.collection('dishes').get();

      return dishSnap.docs
          .map(
            (doc) => {
              'dishId': doc.id,
              ...doc.data(),
              ...chefData,
              'chefId': chefId,
            },
          )
          .toList();
    });

    // Await all futures in parallel
    final postsPerChef = await Future.wait(postFutures);

    // Flatten the list of lists
    for (final postList in postsPerChef) {
      allPosts.addAll(postList);
    }

    allPosts.shuffle(); // Optional
    return allPosts;
  }
}
