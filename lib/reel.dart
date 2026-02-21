import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'chatScreen.dart';
import 'orderscreen.dart';

class VideoModel {
  final String url;
  final String uploaderId;
  final String description;
  final String profileImageUrl;
  final String dishId;
  final String dishName;
  final int price;
  final String chefName;

  VideoModel({
    required this.url,
    required this.uploaderId,
    required this.description,
    required this.profileImageUrl,
    required this.dishId,
    required this.dishName,
    required this.price,
    required this.chefName,
  });
}

class TikTokScreen extends StatefulWidget {
  const TikTokScreen({super.key});
  @override
  State<TikTokScreen> createState() => _TikTokScreenState();
}

class _TikTokScreenState extends State<TikTokScreen> {
  late Future<List<VideoModel>> videosFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    videosFuture = fetchAllVideos();
  }

  Future<List<VideoModel>> fetchAllVideos() async {
    final firestore = FirebaseFirestore.instance;
    List<VideoModel> allVideos = [];

    final userDocs = await firestore.collection('users').get();

    for (var userDoc in userDocs.docs) {
      final profileImageUrl = userDoc.data()['profileImageUrl'] ?? '';
      final chefName = userDoc.data()['rname'] ?? 'Chef';

      final videosSnap = await userDoc.reference.collection('videos').get();

      for (var videoDoc in videosSnap.docs) {
        final videoData = videoDoc.data();
        final videoUrl = videoData['url'];
        final description = videoData['description'] ?? '';
        final dishName = videoData['name'] ?? 'Dish';
        final rawPrice = videoData['price'];
        final price =
            rawPrice is int ? rawPrice : int.tryParse(rawPrice.toString()) ?? 0;

        allVideos.add(
          VideoModel(
            url: videoUrl,
            uploaderId: userDoc.id,
            profileImageUrl: profileImageUrl,
            description: description,
            dishId: videoDoc.id,
            dishName: dishName,
            price: price,
            chefName: chefName,
          ),
        );
      }
    }

    allVideos.shuffle();
    return allVideos;
  }

  void _goToNextVideo() {
    if (_pageController.hasClients) {
      final nextPage = _pageController.page!.toInt() + 1;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousVideo() {
    if (_pageController.hasClients) {
      final previousPage = _pageController.page!.toInt() - 1;
      if (previousPage >= 0) {
        _pageController.animateToPage(
          previousPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<VideoModel>>(
        future: videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            return const Center(child: Text("No videos found"));
          }

          final videos = snapshot.data!;

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return VideoPlayerItem(video: videos[index]);
                },
              ),
              Positioned(
                right: 20,
                top: 100,
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: _goToPreviousVideo,
                    ),
                    const SizedBox(height: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                      ),
                      onPressed: _goToNextVideo,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final VideoModel video;
  const VideoPlayerItem({super.key, required this.video});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.video.url)
      ..initialize().then((_) {
        setState(() => isInitialized = true);
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Video Description'),
            content: Text(description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onLongPress: () => showDescriptionDialog(widget.video.description),
      child: Stack(
        children: [
          isInitialized
              ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
              : const Center(child: CircularProgressIndicator()),

          Positioned(
            right: 15,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      widget.video.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.video.profileImageUrl)
                          : const AssetImage('assets/chat_bg.png')
                              as ImageProvider,
                ),
                const SizedBox(height: 20),

                // Add to Cart
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: () async {
                    if (currentUserId != null) {
                      final cartRef = FirebaseFirestore.instance
                          .collection('user')
                          .doc(currentUserId)
                          .collection('cart')
                          .doc(widget.video.dishId);

                      await cartRef.set({
                        'dishName': widget.video.dishName,
                        'imageUrl': widget.video.url,
                        'price': widget.video.price,
                        'chefId': widget.video.uploaderId,
                        'quantity': 1,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dish added to cart')),
                      );
                    }
                  },
                ),

                // Order
                IconButton(
                  icon: const Icon(
                    Icons.shopping_bag,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => OrderScreen(
                              dishData: {
                                'name': widget.video.dishName,
                                'url': widget.video.url,
                                'price': widget.video.price,
                                'chefId': widget.video.uploaderId,
                              },
                            ),
                      ),
                    );
                  },
                ),

                // Message
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    color: Colors.white,
                    size: 35,
                  ),
                  onPressed: () {
                    if (currentUserId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatScreen(
                                currentUserId: currentUserId,
                                receiverId: widget.video.uploaderId,
                                receiverName: widget.video.chefName,
                                receiverImage: widget.video.profileImageUrl,
                              ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
