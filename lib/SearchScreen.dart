import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'orderscreen.dart';
import 'chatScreen.dart';
import 'ChefProfileScreen.dart';

class SearchScreen extends StatefulWidget {
  final String userId;
  const SearchScreen({super.key, required this.userId});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController searchController = TextEditingController();
  String searchType = 'Dish'; // or 'Chef'
  List<Map<String, dynamic>> allPosts = [];
  List<Map<String, dynamic>> filteredResults = [];
  Map<String, Map<String, dynamic>> uniqueChefs = {};
  bool isSearching = false;
  Set<String> cartDishIds = {};

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    fetchAllChefPosts();
    fetchCartItems();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCartItems() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final cartDocs =
        await FirebaseFirestore.instance
            .collection('user')
            .doc(userId)
            .collection('cart')
            .get();
    setState(() {
      cartDishIds = cartDocs.docs.map((doc) => doc.id).toSet();
    });
  }

  Future<void> fetchAllChefPosts() async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> posts = [];
    Map<String, Map<String, dynamic>> chefs = {};

    final chefDocs =
        await firestore
            .collection('users')
            .where('type', isEqualTo: 'Chef')
            .get();

    for (final chef in chefDocs.docs) {
      final chefData = chef.data();
      final chefId = chef.id;

      chefs[chefId] = {'chefId': chefId, ...chefData};

      final dishSnap = await chef.reference.collection('dishes').get();
      for (final doc in dishSnap.docs) {
        posts.add({
          'dishId': doc.id,
          ...doc.data(),
          ...chefData,
          'chefId': chefId,
        });
      }
    }

    setState(() {
      allPosts = posts;
      uniqueChefs = chefs;
    });
  }

  void _filterResults(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      isSearching = query.isNotEmpty;
      if (searchType == 'Dish') {
        filteredResults =
            allPosts.where((post) {
              return (post['name'] ?? '').toLowerCase().contains(lowerQuery);
            }).toList();
      } else {
        filteredResults =
            uniqueChefs.values.where((chef) {
              return (chef['rname'] ?? '').toLowerCase().contains(lowerQuery);
            }).toList();
      }
    });
  }

  void _onToggleChanged(int index) {
    final newType = (index == 0) ? 'Dish' : 'Chef';
    if (newType != searchType) {
      setState(() {
        searchType = newType;
        _filterResults(searchController.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = isSearching ? filteredResults : [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            // Centered Search Bar with rounded corners and soft shadow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterResults,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    hintText:
                        'Search ${searchType == 'Dish' ? 'dishes' : 'chefs'}...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF8B0000),
                      size: 28,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Animated Segmented Toggle Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('Dish', searchType == 'Dish', 0),
                    _buildToggleButton('Chef', searchType == 'Chef', 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Search results or info
            Expanded(
              child:
                  results.isEmpty && isSearching
                      ? const Center(
                        child: Text(
                          "No results found.",
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: results.length > 10 ? 10 : results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return searchType == 'Dish'
                              ? _buildDishCard(item)
                              : _buildChefCard(item);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected, int index) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B0000) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => _onToggleChanged(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChefCard(Map<String, dynamic> chef) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 35,
          backgroundImage: NetworkImage(chef['profileImageUrl']),
        ),
        title: Text(
          chef['rname'] ?? 'Chef',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        subtitle: Text(
          chef['city'] ?? 'Unknown City',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChefProfileScreen(
                      currentUserId: widget.userId,
                      chefId: chef['chefId'],
                      restaurantName: chef['rname'] ?? 'Chef',
                      description: chef['description'] ?? '',
                      profileImageUrl: chef['profileImageUrl'],
                    ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('View Profile', style: TextStyle(fontSize: 15)),
        ),
      ),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> post) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isInCart = cartDishIds.contains(post['dishId']);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 6,
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(post['profileImageUrl']),
            ),
            title: Text(
              post['rname'] ?? 'Chef',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(post['city'] ?? ''),
          ),

          // Image with fixed aspect ratio and BoxFit.cover
          if (post['url'] != null)
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Image.network(
                post['url'],
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              post['name'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed:
                      isInCart
                          ? null
                          : () async {
                            await FirebaseFirestore.instance
                                .collection('user')
                                .doc(userId)
                                .collection('cart')
                                .doc(post['dishId'])
                                .set({
                                  'dishName': post['name'],
                                  'imageUrl': post['url'],
                                  'price': post['price'] ?? 0,
                                  'chefId': post['chefId'],
                                  'quantity': 1,
                                });
                            setState(() => cartDishIds.add(post['dishId']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dish added to cart'),
                              ),
                            );
                          },
                  icon: Icon(
                    isInCart ? Icons.check : Icons.shopping_cart,
                    color: Colors.white,
                  ),
                  label: const Text(''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

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
                  label: const Text('Order Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(
                    Icons.message,
                    color: Color(0xFF8B0000),
                    size: 30,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatScreen(
                              currentUserId: userId,
                              receiverId: post['chefId'],
                              receiverName: post['rname'],
                              receiverImage: post['profileImageUrl'],
                            ),
                      ),
                    );
                  },
                  tooltip: 'Chat with Chef',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
