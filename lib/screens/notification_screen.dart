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

  Future<void> _markAsRead(String docId) async {
    await FirebaseFirestore.instance.collection('notifications').doc(docId).update({'isRead': true});
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
              String fromUid = data['fromUid'] ?? "";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                builder: (context, userSnap) {
                  String pfp = "";
                  if (userSnap.hasData && userSnap.data!.exists) {
                    var userData = userSnap.data!.data() as Map<String, dynamic>?;
                    pfp = userData?['profilePic'] ?? "";
                  }

                  return GestureDetector(
                    onTap: () => _markAsRead(doc.id),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      color: data['isRead'] == true ? Colors.transparent : Colors.white.withOpacity(0.05),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[900],
                          backgroundImage: pfp.isNotEmpty ? NetworkImage(pfp) : null,
                          child: pfp.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            children: [
                              TextSpan(text: "${data['fromUsername'] ?? 'Someone'} ", style: const TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: data['type'] == "like" ? "liked your post" : "interacted with you"),
                            ],
                          ),
                        ),
                        subtitle: Text(formatTimestamp(data['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
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