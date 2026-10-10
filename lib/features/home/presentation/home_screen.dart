import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../challenges/presentation/challenges_page.dart';
import '../../community/presentation/community_page.dart';
import '../../community/providers/friends_provider.dart';
import '../../community/providers/groups_provider.dart';
import '../../diary/presentation/diary_page.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../profile/presentation/profile_page.dart';
import '../providers/daily_faith_merger.dart';
import 'dashboard_page.dart';

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(
  HomeTabIndexNotifier.new,
);

class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 2;

  void setIndex(int index) => state = index;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    ref.watch(dailyFaithMergerProvider);
    final currentIndex = ref.watch(homeTabIndexProvider);
    final friendRequests = ref.watch(pendingFriendRequestsProvider).value?.length ?? 0;
    final groupRequests = ref.watch(pendingGroupRequestsCountProvider).value ?? 0;
    final unreadChat = ref.watch(unreadChatCountProvider);
    final communityBadge = friendRequests + groupRequests + unreadChat;
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
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
          currentIndex: currentIndex,
          onTap: (index) => ref.read(homeTabIndexProvider.notifier).setIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: ElevaColors.white,
          selectedItemColor: ElevaColors.gold,
          unselectedItemColor: ElevaColors.textMuted,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 26,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.edit_note_rounded),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: communityBadge > 0,
                label: Text('$communityBadge', style: const TextStyle(fontSize: 10)),
                backgroundColor: ElevaColors.gold,
                child: const Icon(Icons.groups_rounded),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}

