import 'package:finalproject_mobapp/Auth.dart';
import 'package:finalproject_mobapp/InputKuis.dart';
import 'package:finalproject_mobapp/Setting.dart';
import 'package:finalproject_mobapp/SoalEssay.dart';
import 'package:finalproject_mobapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final AuthService authService = AuthService();
  String userType = AuthService.userTypeStudent;
  String displayName = '';
  int index = 0;

  // Key for Input Kuis tab to refresh it when profile is updated
  final GlobalKey<InputKuisTabState> _inputKuisKey = GlobalKey<InputKuisTabState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('userType') ?? AuthService.userTypeStudent;
      displayName = prefs.getString('displayName') ?? '';
    });
    print('Navigation: Loaded user type: $userType');
  }

  // Callback when profile is updated from Settings
  void _onProfileUpdated() async {
    print('Navigation: Profile updated from Settings, reloading user data...');
    
    // Reload user data from preferences
    await _loadUserData();
    
    // Refresh the Input Kuis tab to reload user type
    if (_inputKuisKey.currentState != null) {
      _inputKuisKey.currentState!.refreshUserType();
      print('Navigation: Input Kuis tab refreshed');
    }
    
    // Show a snackbar to inform user about the mode change
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mode berhasil diubah! Input Kuis telah diperbarui.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              index = 1; // Navigate to Input Kuis tab
            });
          },
        ),
      ),
    );
  }

  // Method untuk mendapatkan pages - 3 tabs only: Home, Input Kuis, Settings
  List<Widget> _getPages() {
    List<Widget> pages = [
      Home(), // Home selalu ada di index 0
      
      // Input Kuis dengan mode switching otomatis berdasarkan user type
      InputKuisTab(
        key: _inputKuisKey,
        authService: authService,
      ),
      
      // Settings dengan profile integration dan callback
      SettingsPage(
        authService: authService,
        onProfileUpdated: _onProfileUpdated,
      ),
    ];

    return pages;
  }

  // Method untuk mendapatkan navigation items - 3 tabs only
  List<BottomNavigationBarItem> _getNavItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        activeIcon: Icon(Icons.home, size: 28),
        label: "Home",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.quiz),
        activeIcon: Icon(Icons.quiz, size: 28),
        label: "Input Kuis", // Always show as "Input Kuis" - content will change based on mode
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        activeIcon: Icon(Icons.settings, size: 28),
        label: "Settings", // Settings now contains profile functionality
      ),
    ];

    return items;
  }

  void _onTabTapped(int selectedIndex) {
    setState(() {
      index = selectedIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navItems = _getNavItems();
    final pages = _getPages();

    // Pastikan index tidak melebihi jumlah pages yang tersedia
    if (index >= pages.length) {
      index = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.blue[200],
        backgroundColor: Colors.blue[50],
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
        elevation: 8,
        currentIndex: index,
        items: navItems,
        onTap: _onTabTapped,
      ),
    );
  }
}