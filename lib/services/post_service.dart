import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Function para mag-upload at mag-save
  Future<void> uploadPost({
    required String uid,
    required String username,
    required String caption,
    required Uint8List imageData,
  }) async {
    // 1. Upload Image
    String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child('posts/$fileName');

    UploadTask uploadTask = ref.putData(imageData, SettableMetadata(contentType: 'image/jpeg'));
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    // 2. Save Data sa Firestore
    await _firestore.collection('posts').add({
      'uid': uid,
      'username': username,
      'caption': caption,
      'imageUrl': downloadUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}