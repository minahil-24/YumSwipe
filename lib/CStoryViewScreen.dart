import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';

class CStoryViewScreen extends StatefulWidget {
  final String chefId;
  final String storyId;

  const CStoryViewScreen({
    super.key,
    required this.chefId,
    required this.storyId,
  });

  @override
  State<CStoryViewScreen> createState() => _CStoryViewScreenState();
}

class _CStoryViewScreenState extends State<CStoryViewScreen> {
  String? mediaUrl;
  bool isVideo = false;
  bool isLoading = true;
  VideoPlayerController? _controller;
  int likeCount = 0;
  bool liked = false;
  String chefName = '';
  String chefImage = '';
  List<DocumentSnapshot> storyDocs = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  Future<void> _loadStories() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.chefId)
            .collection('stories')
            .orderBy('createdAt', descending: false)
            .get();

    if (snapshot.docs.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    storyDocs = snapshot.docs;
    currentIndex = storyDocs.indexWhere((doc) => doc.id == widget.storyId);
    if (currentIndex == -1) currentIndex = 0;

    await _loadCurrentStory();
  }

  Future<void> _loadCurrentStory() async {
    setState(() => isLoading = true);
    _controller?.dispose();

    final doc = storyDocs[currentIndex];
    final data = doc.data() as Map<String, dynamic>;
    final url = data['url'];
    likeCount = data['likes'] ?? 0;

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.chefId)
            .get();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final likeDoc =
        await FirebaseFirestore.instance
            .collection('user')
            .doc(uid)
            .collection('liked_stories')
            .doc(doc.id)
            .get();

    setState(() {
      mediaUrl = url;
      liked = likeDoc.exists;
      chefName = userDoc['rname'] ?? 'Chef';
      chefImage = userDoc['profileImageUrl'];
      isVideo = url.toLowerCase().endsWith('.mp4');
    });

    if (isVideo) {
      _controller = VideoPlayerController.network(url)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _controller!.setLooping(true);
        });
    }

    setState(() => isLoading = false);
  }

  Future<void> _likeStory() async {
    if (liked) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final currentStoryId = storyDocs[currentIndex].id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.chefId)
        .collection('stories')
        .doc(currentStoryId)
        .update({'likes': FieldValue.increment(1)});

    await FirebaseFirestore.instance
        .collection('user')
        .doc(uid)
        .collection('liked_stories')
        .doc(currentStoryId)
        .set({'likedAt': Timestamp.now()});

    setState(() {
      liked = true;
      likeCount += 1;
    });
  }

  void _nextStory() {
    if (currentIndex + 1 < storyDocs.length) {
      setState(() => currentIndex++);
      _loadCurrentStory();
    }
  }

  void _prevStory() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _loadCurrentStory();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
                  // Story media
                  Center(
                    child:
                        mediaUrl == null
                            ? const Text(
                              "No story",
                              style: TextStyle(color: Colors.white),
                            )
                            : isVideo
                            ? AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            )
                            : Image.network(mediaUrl!, fit: BoxFit.contain),
                  ),

                  // Chef info bar
                  Positioned(
                    top: 40,
                    left: 20,
                    right: 20,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(chefImage),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          chefName,
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

                  // Like button (left)
                  Positioned(
                    bottom: 40,
                    left: 30,
                    child: Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            size: 28,
                            color: const Color(0xFF8B0000),
                          ),
                          onPressed: liked ? null : _likeStory,
                        ),
                      ],
                    ),
                  ),

                  // Like count (right)
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

                  // Navigation arrows
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
                  if (currentIndex < storyDocs.length - 1)
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
