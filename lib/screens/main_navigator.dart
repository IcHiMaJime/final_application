import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'post_screen.dart';
import 'profile_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  // this variable tracks which tab is currently selected (0 = Home, 1 = Search, etc.)
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    AddPostPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // allows the body content to go behind the bottom navigation bar
      extendBody: true,

      // shows the screen based on the current _selectedIndex
      body: _pages[_selectedIndex],

      // floating Navigation Bar at the bottom
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              // BackdropFilter creates the "Glassmorphism" or blur effect
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  // Semi-transparent dark background for the bar
                  color: Colors.grey[900]!.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // calling the helper function for each navigation item
                    _buildNavItem(0, Icons.home_outlined, Icons.home, "Home"),
                    _buildNavItem(1, Icons.search_outlined, Icons.search, "Search"),
                    _buildNavItem(2, Icons.add_box_outlined, Icons.add_box, "Post"),
                    _buildNavItem(3, Icons.person_outline, Icons.person, "Profile"),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // to build the icons/buttons in the navigation bar
  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _selectedIndex == index; // Checks if this button is active

    return GestureDetector(
      // when tapped, update the _selectedIndex and refresh the UI
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // Smooth transition for selection
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // only the selected item gets a subtle highlight background
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon, // Changes icon to "filled" when selected
              color: Colors.white,
              size: 26,
            ),
            // only show the Text Label if the item is selected
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}