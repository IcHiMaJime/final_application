import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final String postUid;
  final String username;
  final String imageUrl;
  final String caption;
  final int initialLikes;
  final dynamic timestamp;

  const PostCard({
    super.key,
    required this.postId,
    required this.postUid,
    required this.username,
    required this.imageUrl,
    required this.initialLikes,
    required this.caption,
    this.timestamp,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool isLiked = false;
  late int likeCount;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    likeCount = widget.initialLikes;
    _checkIfLiked(); // Alamin agad kung na-like na ng user ang post pagka-load
  }

  // Tinitingnan sa Firestore kung ang UID ng current user ay nasa 'likes' sub-collection ng post
  void _checkIfLiked() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(currentUser.uid)
        .get();

    if (mounted) {
      setState(() {
        isLiked = doc.exists; // Kung nage-exist ang document, ibig sabihin liked na ito
      });
    }
  }

  // Function para magpadala ng notification sa may-ari ng post (like o comment)
  Future<void> _sendNotification(String type) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    // Huwag mag-notif kung sarili mong post ang ni-like/comment mo
    if (currentUser == null || currentUser.uid == widget.postUid) return;

    // Kunin ang username ng nag-action para sa notification message
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    String fromUsername = "Someone";
    if (userDoc.exists && userDoc.data() != null) {
      fromUsername = (userDoc.data() as Map<String, dynamic>)['username'] ?? "Someone";
    }

    // I-save ang notification details sa Firestore
    await FirebaseFirestore.instance.collection('notifications').add({
      'type': type,
      'fromUid': currentUser.uid,
      'fromUsername': fromUsername,
      'toUid': widget.postUid,
      'postId': widget.postId,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Kino-convert ang Firestore Timestamp sa madaling basahin na format (e.g., 5m ago)
  String formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = (timestamp as Timestamp).toDate();
    Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d').format(date);
  }

  // Pag-save ng bagong comment sa database
  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    String commentText = _commentController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    String myUsername = "User";
    if (userDoc.exists && userDoc.data() != null) {
      var userData = userDoc.data() as Map<String, dynamic>;
      myUsername = userData['username'] ?? user.email?.split('@')[0] ?? "User";
    }

    // Idagdag ang comment sa sub-collection ng specific post
    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').add({
      'uid': user.uid,
      'username': myUsername,
      'comment': commentText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _sendNotification("comment"); // Notif para sa may-ari ng post
    _commentController.clear(); // Burahin ang text sa field pagkatapos mag-send
  }

  // Modal Bottom Sheet para sa Comments section
  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para pwedeng itaas ang modal kapag lumabas ang keyboard
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1D23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Handle bar sa taas ng modal
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text("Comments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Real-time listener para sa mga comments
                stream: FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FutureBuilder para makuha ang Profile Pic ng nag-comment
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(data['uid']).get(),
                              builder: (context, userSnap) {
                                String pfp = "";
                                if (userSnap.hasData && userSnap.data!.exists && userSnap.data!.data() != null) {
                                  var userData = userSnap.data!.data() as Map<String, dynamic>;
                                  pfp = userData['profilePic'] ?? "";
                                }
                                return CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[800],
                                    backgroundImage: pfp.isNotEmpty ? NetworkImage(pfp) : null,
                                    child: pfp.isEmpty ? const Icon(Icons.person, size: 18, color: Colors.white) : null
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(data['username'] ?? "User", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 8),
                                    Text(formatTime(data['timestamp']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(data['comment'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 10),
                                  // Actions sa bawat comment: Copy at Delete
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: data['comment'] ?? ""));
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Comment copied!"), duration: Duration(seconds: 1)));
                                        },
                                        child: const Row(children: [
                                          Icon(Icons.copy, color: Colors.grey, size: 14),
                                          SizedBox(width: 4),
                                          Text("Copy", style: TextStyle(color: Colors.grey, fontSize: 11))
                                        ]),
                                      ),
                                      const SizedBox(width: 20),
                                      GestureDetector(
                                        onTap: () {
                                          FirebaseFirestore.instance.collection('posts').doc(widget.postId).collection('comments').doc(doc.id).delete();
                                        },
                                        child: const Row(children: [
                                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                                          SizedBox(width: 4),
                                          Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 11))
                                        ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Textfield input para sa bagong comment
            Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                  left: 15, right: 15, top: 10
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Add a comment...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _submitComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Profile picture, Username, at Post Settings (More icon)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage(uid: widget.postUid))
                  );
                },
                child: Row(
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(widget.postUid).get(),
                      builder: (context, snapshot) {
                        String profilePic = "";
                        if (snapshot.hasData && snapshot.data!.exists && snapshot.data!.data() != null) {
                          var userData = snapshot.data!.data() as Map<String, dynamic>;
                          profilePic = userData['profilePic'] ?? "";
                        }
                        return CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                          child: profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.username, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        Text(formatTime(widget.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              // Popup Menu para sa Save at About Artist
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                color: const Color(0xFF1A1D23),
                onSelected: (value) async {
                  if (value == 'save') {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) return;
                    // I-save ang post details sa 'saved' collection ng user
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .collection('saved')
                        .doc(widget.postId)
                        .set({
                      'postId': widget.postId,
                      'postUid': widget.postUid,
                      'username': widget.username,
                      'caption': widget.caption,
                      'likes': widget.initialLikes,
                      'imageUrl': widget.imageUrl,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Art saved to your profile!")),
                      );
                    }
                  } else if (value == 'about') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage(uid: widget.postUid))
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_border, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text("Save Art", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text("About Artist", style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // BODY: Mismong imahe ng post
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: widget.imageUrl.startsWith('http')
                ? Image.network(widget.imageUrl, width: double.infinity, height: 350, fit: BoxFit.cover)
                : Image.asset(widget.imageUrl, width: double.infinity, height: 350, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          // FOOTER: Like button at Comment button
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) return;

                  final likeDoc = FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('likes')
                      .doc(currentUser.uid);

                  if (isLiked) {
                    // Kung i-unlike: Tanggalin ang document at bawasan ang like count
                    await likeDoc.delete();
                    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                      'likes': FieldValue.increment(-1),
                    });
                  } else {
                    // Kung i-like: Mag-add ng document at dagdagan ang like count
                    await likeDoc.set({'uid': currentUser.uid});
                    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
                      'likes': FieldValue.increment(1),
                    });
                    await _sendNotification("like");
                  }

                  if (mounted) {
                    setState(() {
                      isLiked = !isLiked;
                      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
                    });
                  }
                },
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white, size: 26),
                    const SizedBox(width: 8),
                    Text("$likeCount", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showComments(context),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 24, color: Colors.white),
                    const SizedBox(width: 8),
                    // Real-time update para sa comment count
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return Text("$count", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // CAPTION: Pinagsamang Bold Username at normal na text para sa caption
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "${widget.username} ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: widget.caption, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}