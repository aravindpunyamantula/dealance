import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../features/feed/feed_screen.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/deals/deals_screen.dart';
import '../pages/ideas/my_ideas_screen.dart';
import '../pages/entrepreneur/discover_investors_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/app_palette.dart';

/// Entrepreneur Navigation — Feed, My Ideas, Discover, Deals, Profile
class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => NavigationState();
}

class NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    FeedScreen(),
    MyIdeasScreen(),
    DiscoverInvestorsScreen(),
    DealsScreen(),
    ProfileScreen(),
  ];

  void switchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppPalette.background,
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppPalette.surfaceCard,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            selectedItemColor: AppPalette.primaryAccent,
            unselectedItemColor: AppPalette.textSecondary,
            selectedLabelStyle: const TextStyle(fontFamily: "Poppins", fontSize: 10, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontFamily: "Poppins", fontSize: 10, fontWeight: FontWeight.w400),
            items: const [
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.house), activeIcon: Icon(CupertinoIcons.house_fill), label: "Feed"),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.lightbulb), activeIcon: Icon(CupertinoIcons.lightbulb_fill), label: "Ideas"),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.compass), activeIcon: Icon(CupertinoIcons.compass_fill), label: "Discover"),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.briefcase), activeIcon: Icon(CupertinoIcons.briefcase_fill), label: "Deals"),
              BottomNavigationBarItem(icon: Icon(CupertinoIcons.person), activeIcon: Icon(CupertinoIcons.person_solid), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}
