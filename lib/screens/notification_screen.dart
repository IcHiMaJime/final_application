import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('MMM d, h:mm a').format(date);
  }

  // --- UPDATED FUNCTION PARA I-SHOW ANG MGA REAL COMMENTS ---
  void _showCommentsModal(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Comments",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No comments yet.", style: TextStyle(color: Colors.white54)),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var commentData = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                        String userComment = commentData['commentText'] ?? commentData['comment'] ?? "";
                        String commenterName = commentData['username'] ?? "Anonymous";
                        String commenterPfp = commentData['profilePic'] ?? "";

                        // --- FORMAT NG ORAS NG COMMENT ---
                        String commentTime = "";
                        if (commentData['timestamp'] != null) {
                          DateTime dt = (commentData['timestamp'] as Timestamp).toDate();
                          commentTime = DateFormat('h:mm a').format(dt);
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[900],
                            backgroundImage: commenterPfp.isNotEmpty ? NetworkImage(commenterPfp) : null,
                            child: commenterPfp.isEmpty ? const Icon(Icons.person, size: 18, color: Colors.white24) : null,
                          ),
                          title: Row(
                            children: [
                              Text(
                                commenterName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              // Oras sa tabi ng pangalan
                              Text(
                                commentTime,
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              userComment,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Add Comment Field
              Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    left: 16, right: 16, top: 8
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Add a comment...",
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markAsRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> _acceptRequest(String notifId, String requesterUid, String myUid) async {
    await FirebaseFirestore.instance.collection('users').doc(myUid).collection('followers').doc(requesterUid).set({
      'uid': requesterUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('users').doc(requesterUid).collection('following').doc(myUid).set({
      'uid': myUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({
      'status': 'accepted',
      'isRead': true,
    });
  }

  Future<void> _deleteRequest(String notifId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({
      'status': 'deleted',
      'isRead': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF02050A),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toUid', isEqualTo: currentUid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String type = data['type'] ?? "";
              String status = data['status'] ?? "pending";
              String fromUid = data['fromUid'] ?? "";
              String name = data['fromUsername'] ?? "Someone";
              String postId = data['postId'] ?? "";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                builder: (context, userSnap) {
                  String pfp = (userSnap.hasData && userSnap.data!.exists) ? userSnap.data!['profilePic'] ?? "" : "";

                  return GestureDetector(
                    onTap: () {
                      _markAsRead(doc.id);
                      if (type == "comment" && postId.isNotEmpty) {
                        _showCommentsModal(context, postId);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      color: data['isRead'] == true ? Colors.transparent : Colors.white.withOpacity(0.05),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[900],
                              backgroundImage: pfp.isNotEmpty ? NetworkImage(pfp) : null,
                              child: pfp.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                children: [
                                  TextSpan(text: "$name ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(
                                      text: type == "follow_request"
                                          ? "requested to follow you"
                                          : type == "like" ? "liked your post" : "commented on your post",
                                      style: const TextStyle(color: Colors.white70)
                                  ),
                                ],
                              ),
                            ),
                            subtitle: Text(formatTimestamp(data['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            trailing: type == "like"
                                ? const Icon(Icons.favorite, color: Colors.red, size: 16)
                                : type == "comment" ? const Icon(Icons.chat_bubble, color: Colors.blueAccent, size: 16) : null,
                          ),
                          if (type == "follow_request" && status == "pending")
                            Padding(
                              padding: const EdgeInsets.only(left: 72, bottom: 12),
                              child: Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                                    onPressed: () => _acceptRequest(doc.id, fromUid, currentUid),
                                    child: const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => _deleteRequest(doc.id),
                                    child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  ),
                                ],
                              ),
                            )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}