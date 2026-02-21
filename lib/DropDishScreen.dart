import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class DropDishScreen extends StatefulWidget {
  const DropDishScreen({super.key});

  @override
  State<DropDishScreen> createState() => _DropDishScreenState();
}

class _DropDishScreenState extends State<DropDishScreen> {
  File? _imageFile;
  Uint8List? _webImageBytes;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<String> _uploadImageToCloudinary() async {
    const cloudName = 'dhwt4pwb7';
    const uploadPreset = 'img_posts';

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb && _webImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _webImageBytes!,
          filename: 'upload.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else if (_imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('file', _imageFile!.path),
      );
    } else {
      throw Exception('No image selected');
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
    if ((_imageFile == null && _webImageBytes == null) ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Fill all fields and select an image.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final imageUrl = await _uploadImageToCloudinary();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dishes')
          .add({
            'name': _nameController.text.trim(),
            'price': _priceController.text.trim(),
            'description': _descController.text.trim(),
            'time': Timestamp.now(),
            'url': imageUrl,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Dish uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _imageFile = null;
        _webImageBytes = null;
        _nameController.clear();
        _priceController.clear();
        _descController.clear();
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_webImageBytes != null) {
      imageProvider = MemoryImage(_webImageBytes!);
    }

    InputDecoration customInput(String label) {
      return InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF8B0000)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF8B0000)),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF8B0000)),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo11.png', height: 40),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF8B0000)),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEDED),
                  border: Border.all(color: const Color(0xFF8B0000)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    imageProvider != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image(image: imageProvider, fit: BoxFit.cover),
                        )
                        : const Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Color(0xFF8B0000),
                        ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: customInput('Dish Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: customInput('Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: customInput('Description'),
            ),
            const SizedBox(height: 25),
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
                    color: const Color(0xFF8B0000),
                    backgroundColor: Colors.grey[300],
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
                      : const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Dish',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B0000),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
