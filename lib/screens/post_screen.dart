import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});
  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final TextEditingController _captionController = TextEditingController();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageData;
  bool _isLoading = false;

  String _selectedCategory = "Digital Art";
  final List<String> categories = [
    "Digital Art", "Oil Painting", "3D Render", "Sketch", "Pixel Art", "Cyberpunk"
  ];

  final cloudinary = CloudinaryPublic('ddwpbwvgp', 'app_amc', cache: false);

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (selected != null) {
      var bytes = await selected.readAsBytes();
      setState(() => _imageData = bytes);
    }
  }

  Future<void> _handlePostArt() async {
    final String caption = _captionController.text.trim();
    if (_imageData == null || caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image and add a caption."))
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.getCurrentUser();
      if (user == null) throw "Kailangan mong mag-login muli.";

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          _imageData!,
          identifier: 'art_${DateTime.now().millisecondsSinceEpoch}',
          folder: 'posts',
        ),
      );

      String username = await _authService.getCurrentUsername();

      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'username': username,
        'caption': caption,
        'category': _selectedCategory,
        'imageUrl': response.secureUrl,
        'likes': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        // I-pop muna ang screen bago ang SnackBar para iwas white screen
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Art posted successfully! ✨"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02050A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Post Art", style: TextStyle(color: Colors.white)),
        actions: [
          if (!_isLoading)
            IconButton(
                onPressed: _handlePostArt,
                icon: const Icon(Icons.check, color: Colors.white)
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Category", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedCategory == categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _selectedCategory = categories[index]),
                      label: Text(categories[index]),
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white10,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "What's the story?",
                hintStyle: TextStyle(color: Colors.white24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
                child: _imageData != null
                    ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(_imageData!, fit: BoxFit.cover)
                )
                    : const Icon(Icons.add_a_photo, color: Colors.white24, size: 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}