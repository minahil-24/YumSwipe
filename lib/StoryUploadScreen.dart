import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mime/mime.dart';

class StoryUploadScreen extends StatefulWidget {
  const StoryUploadScreen({super.key});

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  Uint8List? _webFile;
  io.File? _file;
  String? _fileType;
  String? _fileName;
  final _captionController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();

    final picked =
        await picker.pickImage(source: ImageSource.gallery) ??
        await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      final mimeType = lookupMimeType(picked.name);
      _fileType = mimeType?.startsWith('video') == true ? 'video' : 'image';

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webFile = bytes;
          _fileName = picked.name;
          _file = null;
        });
      } else {
        setState(() {
          _file = io.File(picked.path);
          _fileName = picked.name;
          _webFile = null;
        });
      }
    }
  }

  Future<String> _uploadToCloudinary() async {
    const cloudName = 'dhwt4pwb7';
    const uploadPreset = 'stories';
    final endpoint =
        'https://api.cloudinary.com/v1_1/$cloudName/${_fileType == 'video' ? 'video' : 'image'}/upload';

    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb && _webFile != null && _fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', _webFile!, filename: _fileName),
      );
    } else if (_file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', _file!.path));
    } else {
      throw Exception('No media selected');
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    final data = jsonDecode(resBody);
    return data['secure_url'];
  }

  Future<void> _uploadStory() async {
    if ((_file == null && _webFile == null) ||
        _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select media and add a caption')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final url = await _uploadToCloudinary();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final now = Timestamp.now();
      final expiry = Timestamp.fromDate(
        now.toDate().add(const Duration(hours: 24)),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('stories')
          .add({
            'url': url,
            'caption': _captionController.text.trim(),
            'type': _fileType,
            'createdAt': now,
            'expiresAt': expiry,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story uploaded successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaPreview =
        (_file != null || _webFile != null)
            ? _fileType == 'video'
                ? const Icon(Icons.videocam, size: 40, color: Colors.red)
                : kIsWeb
                ? Image.memory(_webFile!, fit: BoxFit.cover)
                : Image.file(_file!, fit: BoxFit.cover)
            : const Icon(Icons.add_a_photo, size: 40);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spice Story'),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: mediaPreview),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Add a caption...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon:
                  _isUploading
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.upload, color: Colors.white),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Story',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: _isUploading ? null : _uploadStory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
