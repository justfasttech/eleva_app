import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../challenges/presentation/challenges_page.dart';
import '../../community/presentation/community_page.dart';
import '../../diary/presentation/diary_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../providers/hourly_faith_merger.dart';
import 'dashboard_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    ref.watch(hourlyFaithMergerProvider);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChallengesPage(),
          DiaryPage(),
          DashboardPage(),
          CommunityPage(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ElevaColors.white,
          selectedItemColor: ElevaColors.gold,
          unselectedItemColor: ElevaColors.textMuted,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 26,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

