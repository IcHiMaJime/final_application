import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart'; // Siguraduhing installed ito

class EditProfilePage extends StatefulWidget {
  final String currentUsername;
  final String currentBio;
  final String currentProfilePic;

  const EditProfilePage({super.key, required this.currentUsername, required this.currentBio, required this.currentProfilePic});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  Uint8List? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _bioController = TextEditingController(text: widget.currentBio);
  }

  // Cloudinary Upload Logic
  Future<String?> _uploadToCloudinary(Uint8List imageBytes) async {
    try {
      final cloudinary = CloudinaryPublic('ddwpbwvgp', 'app_amc', cache: false);
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          imageBytes,
          identifier: 'profile_${DateTime.now().millisecondsSinceEpoch}',
          folder: 'profile_pics',
        ),
      );
      return response.secureUrl;
    } catch (e) {
      print("Cloudinary Error: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      var bytes = await image.readAsBytes();
      setState(() => _imageFile = bytes);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String? newImageUrl;

      // I-upload muna ang image kung may napili
      if (_imageFile != null) {
        newImageUrl = await _uploadToCloudinary(_imageFile!);
      }

      Map<String, dynamic> updateData = {
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
      };

      if (newImageUrl != null) {
        updateData['profilePic'] = newImageUrl;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(updateData);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02050A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: _isLoading ? null : _saveProfile,
              icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.check, color: Colors.blueAccent)
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white10,
                backgroundImage: _imageFile != null
                    ? MemoryImage(_imageFile!)
                    : (widget.currentProfilePic.isNotEmpty ? NetworkImage(widget.currentProfilePic) : null) as ImageProvider?,
                child: (_imageFile == null && widget.currentProfilePic.isEmpty)
                    ? const Icon(Icons.add_a_photo, color: Colors.white54, size: 30)
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            _buildField("Username", _usernameController),
            const SizedBox(height: 20),
            _buildField("Bio", _bioController, maxLines: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
      ),
    );
  }
}