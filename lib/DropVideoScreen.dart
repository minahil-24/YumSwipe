import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class DropDishScreen extends StatefulWidget {
  const DropDishScreen({super.key});

  @override
  State<DropDishScreen> createState() => _DropDishScreenState();
}

class _DropDishScreenState extends State<DropDishScreen> {
  File? _videoFile;
  Uint8List? _webVideoBytes;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webVideoBytes = bytes;
          _videoFile = null;
        });
      } else {
        setState(() {
          _videoFile = File(picked.path);
          _webVideoBytes = null;
        });
      }
    }
  }

  Future<String> _uploadVideoToCloudinary() async {
    const cloudName = 'dhwt4pwb7';
    const uploadPreset = 'flicks';
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
    );

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb && _webVideoBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _webVideoBytes!,
          filename: 'upload.mp4',
        ),
      );
    } else if (_videoFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', _videoFile!.path),
      );
    } else {
      throw Exception('No video selected');
    }

    final streamedResponse = await request.send();
    final contentLength = streamedResponse.contentLength ?? 0;
    final responseBytes = <int>[];
    int received = 0;

    final completer = Completer<String>();

    streamedResponse.stream.listen(
      (chunk) {
        responseBytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          setState(() {
            _uploadProgress = received / contentLength;
          });
        }
      },
      onDone: () {
        final responseString = utf8.decode(responseBytes);
        final data = json.decode(responseString);
        completer.complete(data['secure_url']);
      },
      onError: (error) {
        completer.completeError('Cloudinary upload failed: $error');
      },
      cancelOnError: true,
    );

    return await completer.future;
  }

  Future<void> _uploadDish() async {
    final isEmpty = (_videoFile == null && _webVideoBytes == null);
    if (isEmpty ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select a video.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final videoUrl = await _uploadVideoToCloudinary();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('videos')
          .add({
            'name': _nameController.text.trim(),
            'price': _priceController.text.trim(),
            'description': _descController.text.trim(),
            'time': Timestamp.now(),
            'url': videoUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dish uploaded successfully!')),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading dish: $e')));
    } finally {
      setState(() {
        _isUploading = false;
        _videoFile = null;
        _webVideoBytes = null;
        _nameController.clear();
        _priceController.clear();
        _descController.clear();
        _uploadProgress = 0.0;
      });
    }
  }

  InputDecoration _customInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _videoPreview() {
    final hasVideo = _videoFile != null || _webVideoBytes != null;
    return Icon(
      hasVideo ? Icons.videocam : Icons.add_a_photo,
      size: 40,
      color: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 40),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.red),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: _videoPreview()),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: _customInputDecoration('Dish Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: _customInputDecoration('Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: _customInputDecoration('Description'),
            ),
            const SizedBox(height: 30),
            if (_isUploading)
              Column(
                children: [
                  const Text(
                    "Uploading...",
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    color: Colors.red,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadDish,
              icon:
                  _isUploading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.upload, color: Colors.white),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Post',
                style: const TextStyle(color: Colors.white),
              ),
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
