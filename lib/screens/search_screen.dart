import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'profile_screen.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _selectedCategory = "";
  String _searchQuery = "";
  List<String> _recentSearches = [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    "Digital Art", "Oil Painting", "3D Render", "Sketch", "Pixel Art", "Cyberpunk"
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  // RECENT SEARCH LOGIC
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _addToRecent(String query) async {
    String cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> currentList = prefs.getStringList('recent_searches') ?? [];

    // Alisin ang duplicate at ilagay sa unahan
    currentList.remove(cleanQuery);
    currentList.insert(0, cleanQuery);

    // Limit to top 10
    if (currentList.length > 10) currentList.removeLast();

    await prefs.setStringList('recent_searches', currentList);
    _loadRecentSearches(); // I-refresh ang UI
  }

  Future<void> _removeFromRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(query);
    await prefs.setStringList('recent_searches', _recentSearches);
    setState(() {}); // Force UI update
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02050A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              onSubmitted: (val) {
                _addToRecent(val);
              },
              decoration: InputDecoration(
                hintText: "Search masterpieces or users...",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. RECENT SEARCHES (Laging lalabas sa taas kung may history) ---
            if (_recentSearches.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("Recent", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recentSearches.length,
                  itemBuilder: (context, index) {
                    final query = _recentSearches[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(query),
                        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                        backgroundColor: Colors.white.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        onPressed: () {
                          setState(() {
                            _searchQuery = query;
                            _searchController.text = query;
                          });
                        },
                        avatar: GestureDetector(
                          onTap: () => _removeFromRecent(query),
                          child: const Icon(Icons.close, size: 14, color: Colors.white38),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // --- 2. USER SEARCH RESULTS ---
            if (_searchQuery.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isGreaterThanOrEqualTo: _searchQuery)
                    .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Text("Suggested Users", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var userData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: (userData['profilePic'] ?? "").isNotEmpty ? NetworkImage(userData['profilePic']) : null,
                              child: (userData['profilePic'] ?? "").isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(userData['username'] ?? '', style: const TextStyle(color: Colors.white)),
                            onTap: () {
                              _addToRecent(_searchQuery);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(uid: snapshot.data!.docs[index].id)));
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),

            // --- 3. CATEGORIES & GRID ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text("Explore Art", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),

            // Categories logic (same as original)
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (selected) => setState(() => _selectedCategory = selected ? cat : ""),
                      label: Text(cat),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12),
                      selectedColor: const Color(0xFF6366F1),
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // Art Grid (same as original)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: _selectedCategory.isEmpty
                    ? FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots()
                    : FirebaseFirestore.instance.collection('posts').where('category', isEqualTo: _selectedCategory).orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var post = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(post['imageUrl'] ?? '', fit: BoxFit.cover),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}