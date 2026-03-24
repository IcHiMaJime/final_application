import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String username;
  final String caption;
  final String imageUrl;
  final DateTime timestamp;

  PostModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
  });

  // I-convert ang Firestore document papuntang Object
  factory PostModel.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      username: data['username'] ?? 'Artist',
      caption: data['caption'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}