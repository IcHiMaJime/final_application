import 'dart:ui'; // Import para sa ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_profile_screen.dart';
import '../widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---

  void _checkIfFollowing() async {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    String targetUid = widget.uid ?? currentUid;
    if (currentUid == targetUid) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .collection('followers')
        .doc(currentUid)
        .get();

    if (mounted) {
      setState(() => isFollowing = doc.exists);
    }
  }

  Future<void> _toggleFollow() async {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    String targetUid = widget.uid ?? "";
    if (targetUid.isEmpty || currentUid == targetUid) return;

    if (isFollowing) {
      await FirebaseFirestore.instance.collection('users').doc(targetUid).collection('followers').doc(currentUid).delete();
      await FirebaseFirestore.instance.collection('users').doc(currentUid).collection('following').doc(targetUid).delete();
      setState(() => isFollowing = false);
    } else {
      DocumentSnapshot myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      String myUsername = (myDoc.data() as Map<String, dynamic>)['username'] ?? "Someone";

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'follow_request',
        'fromUid': currentUid,
        'fromUsername': myUsername,
        'toUid': targetUid,
        'status': 'pending',
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Follow request sent!")));
    }
  }

  // --- DELETE FUNCTIONS ---

  // Para sa sariling Post
  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post deleted")));
    }
  }

  // Para sa Saved Art (Bookmark)
  void _deleteSavedArt(String postId) async {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('saved')
          .doc(postId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Removed from saved arts"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting save: $e");
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D23),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Logout', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(child: const Text('No', style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showUsersList(String title, String collectionName, String targetUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        children: [
          Container(margin: const EdgeInsets.only(top: 10), height: 4, width: 40, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(targetUid).collection(collectionName).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return Center(child: Text("No $title yet", style: const TextStyle(color: Colors.grey)));
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    String userListUid = snapshot.data!.docs[index].id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(userListUid).get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox();
                        var data = userSnap.data!.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(backgroundImage: NetworkImage(data['profilePic'] ?? "")),
                          title: Text(data['username'] ?? "User", style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(uid: userListUid)));
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final String targetUid = widget.uid ?? FirebaseAuth.instance.currentUser?.uid ?? "";
    final bool isMe = targetUid == FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(targetUid).snapshots(),
      builder: (context, userSnapshot) {
        String username = "User", bio = "", profilePic = "";
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          username = userData['username'] ?? "User";
          bio = userData['bio'] ?? "";
          profilePic = userData['profilePic'] ?? "";
        }

        return Scaffold(
          backgroundColor: const Color(0xFF02050A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            actions: [
              if (isMe) IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _showLogoutDialog()),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                        radius: 40,
                        backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                        child: profilePic.isEmpty ? const Icon(Icons.person) : null
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn("Posts", FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: targetUid)),
                          GestureDetector(
                            onTap: () => _showUsersList("Followers", "followers", targetUid),
                            child: _buildStatColumn("Followers", FirebaseFirestore.instance.collection('users').doc(targetUid).collection('followers')),
                          ),
                          GestureDetector(
                            onTap: () => _showUsersList("Following", "following", targetUid),
                            child: _buildStatColumn("Following", FirebaseFirestore.instance.collection('users').doc(targetUid).collection('following')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(alignment: Alignment.centerLeft, child: Text(bio, style: const TextStyle(color: Colors.white70))),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isMe || isFollowing ? Colors.white12 : Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    onPressed: isMe
                        ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditProfilePage(
                                currentUsername: username,
                                currentBio: bio,
                                currentProfilePic: profilePic
                            )
                        )
                    )
                        : _toggleFollow,
                    child: Text(isMe ? "Edit Profile" : (isFollowing ? "Unfollow" : "Follow"), style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
              TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on, color: Colors.white)),
                    Tab(icon: Icon(Icons.bookmark_border, color: Colors.white))
                  ]
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // POSTS GRID
                    _buildGrid(FirebaseFirestore.instance.collection('posts').where('uid', isEqualTo: targetUid), isSavedTab: false, isMe: isMe),
                    // SAVED TAB GRID
                    _buildGrid(FirebaseFirestore.instance.collection('users').doc(targetUid).collection('saved'), isSavedTab: true, isMe: isMe),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String label, Query query) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Column(
          children: [
            Text("$count", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }

  Widget _buildGrid(Query query, {required bool isSavedTab, required bool isMe}) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Empty", style: TextStyle(color: Colors.white10)));

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailScreen(postData: data, postId: doc.id)));
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.network(data['imageUrl'] ?? "", fit: BoxFit.cover),
                  ),
                ),

                // 3 DOTS MENU
                // Pinapakita lang kung:
                // 1. Post mo ito (Delete Post)
                // 2. Saved art mo ito (Delete Save)
                if (isMe)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      color: const Color(0xFF1A1D23),
                      onSelected: (value) {
                        if (value == 'delete') {
                          if (isSavedTab) {
                            _deleteSavedArt(doc.id);
                          } else {
                            _deletePost(doc.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                              isSavedTab ? "Delete Save" : "Delete Post",
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13)
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// --- POST DETAIL SCREEN ---

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostDetailScreen({super.key, required this.postData, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: (postData['imageUrl'] ?? "").isNotEmpty
                ? Image.network(postData['imageUrl'], fit: BoxFit.cover)
                : Container(color: Colors.black),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1D23).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: PostCard(
                        postId: postId,
                        postUid: postData['uid'] ?? postData['postUid'] ?? "",
                        username: postData['username'] ?? "User",
                        imageUrl: postData['imageUrl'] ?? "",
                        initialLikes: postData['likes'] ?? 0,
                        caption: postData['caption'] ?? "",
                        timestamp: postData['timestamp'],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}