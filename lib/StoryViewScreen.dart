import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class StoryViewScreen extends StatefulWidget {
  final String chefId;
  final List<Map<String, dynamic>> stories;
  final int initialIndex;
  final String chefName;
  final String profileImageUrl;

  const StoryViewScreen({
    super.key,
    required this.chefId,
    required this.stories,
    required this.initialIndex,
    required this.chefName,
    required this.profileImageUrl,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  int currentIndex = 0;
  String? mediaUrl;
  bool isVideo = false;
  bool isLoading = true;
  VideoPlayerController? _videoController;
  bool liked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    print("🚀 StoryViewScreen started with ${widget.stories.length} stories");
    _loadStory();
  }

  Future<void> _loadStory() async {
    setState(() {
      isLoading = true;
      liked = false;
    });

    _videoController?.dispose();

    final story = widget.stories[currentIndex];
    final storyId = story['id'];
    final url = story['url'];

    print('🎬 Loading story: $storyId');
    print('🌐 Media URL: $url');

    try {
      final storyDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.chefId)
              .collection('stories')
              .doc(storyId)
              .get();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('❌ FirebaseAuth user is null!');
        return;
      }

      final likeDoc =
          await FirebaseFirestore.instance
              .collection('user')
              .doc(uid)
              .collection('liked_stories')
              .doc(storyId)
              .get();

      mediaUrl = url;

      /// ✅ Fix: Use 'type' field instead of missing 'isVideo'
      final type = storyDoc.data()?['type'];
      isVideo = (type == 'video') || url.toLowerCase().endsWith('.mp4');

      likeCount = storyDoc['likes'] ?? 0;
      liked = likeDoc.exists;

      print('📊 Story metadata loaded');
      print('▶️ isVideo: $isVideo, ❤️ Likes: $likeCount, LikedByUser: $liked');

      if (isVideo) {
        print('🎥 Initializing video player...');
        try {
          _videoController = VideoPlayerController.network(url);
          await _videoController!.initialize().timeout(
            const Duration(seconds: 10),
          );

          _videoController!
            ..play()
            ..setLooping(true);

          print('✅ Video initialized and playing');
        } catch (e) {
          print('❌ Failed to load video: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Failed to load video")));
          isVideo = false;
          _videoController = null;
        }
      }
    } catch (e) {
      print('❌ Error loading story: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _nextStory() {
    if (currentIndex + 1 < widget.stories.length) {
      setState(() => currentIndex++);
      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _loadStory();
    }
  }

  Future<void> _toggleLike() async {
    if (liked) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final storyId = widget.stories[currentIndex]['id'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.chefId)
        .collection('stories')
        .doc(storyId)
        .update({'likes': FieldValue.increment(1)});

    await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('liked_stories')
        .doc(storyId)
        .set({'likedAt': Timestamp.now()});

    setState(() {
      liked = true;
      likeCount++;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Center(
                    child:
                        mediaUrl == null
                            ? const Text(
                              "No story found.",
                              style: TextStyle(color: Colors.white),
                            )
                            : isVideo
                            ? AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            )
                            : Image.network(mediaUrl!, fit: BoxFit.contain),
                  ),

                  // Top Bar
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(widget.profileImageUrl),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.chefName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Like Button
                  Positioned(
                    bottom: 40,
                    left: 30,
                    child: IconButton(
                      icon: Icon(
                        liked ? Icons.favorite : Icons.favorite_border,
                        color: const Color(0xFF8B0000),
                        size: 28,
                      ),
                      onPressed: _toggleLike,
                    ),
                  ),

                  // Like Count
                  Positioned(
                    bottom: 47,
                    right: 30,
                    child: Text(
                      '$likeCount likes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Navigation Arrows
                  if (currentIndex > 0)
                    Positioned(
                      left: 10,
                      top: MediaQuery.of(context).size.height / 2 - 30,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white70,
                        ),
                        onPressed: _prevStory,
                      ),
                    ),
                  if (currentIndex < widget.stories.length - 1)
                    Positioned(
                      right: 10,
                      top: MediaQuery.of(context).size.height / 2 - 30,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                        ),
                        onPressed: _nextStory,
                      ),
                    ),
                ],
              ),
    );
  }
}
