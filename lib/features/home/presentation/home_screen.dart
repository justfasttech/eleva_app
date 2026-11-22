import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/eleva_design.dart';
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
      extendBody: true,
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
      bottomNavigationBar: ElevaNavBar(
        currentIndex: currentIndex,
        communityBadge: communityBadge,
        onTap: (index) =>
            ref.read(homeTabIndexProvider.notifier).setIndex(index),
      ),
    );
  }
}

/// Ícones da navbar desenhados em SVG (traço), iguais ao design.
/// Não dependem da fonte MaterialIcons, então aparecem igual no web e no app.
class _NavItem {
  final String svgBody;
  final String label;

  const _NavItem(this.svgBody, this.label);

  String svg(double strokeWidth) =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000000" stroke-width="$strokeWidth" stroke-linecap="round" '
      'stroke-linejoin="round">$svgBody</svg>';
}

/// Barra de navegação flutuante (pílula escura). A aba ativa vira uma
/// pílula dourada com rótulo; as demais mostram só o ícone.
class ElevaNavBar extends StatelessWidget {
  final int currentIndex;
  final int communityBadge;
  final ValueChanged<int> onTap;

  const ElevaNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.communityBadge = 0,
  });

  static const _items = [
    _NavItem(
      '<polygon points="12 3 14.8 8.8 21 9.6 16.5 14 17.6 20.2 12 17.3 6.4 20.2 7.5 14 3 9.6 9.2 8.8"/>',
      'Desafios',
    ),
    _NavItem(
      '<path d="M5 20V5a2 2 0 0 1 2-2h12v15H7a2 2 0 0 0-2 2z"/><path d="M9 7.5h6M9 11h4"/>',
      'Diário',
    ),
    _NavItem(
      '<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>',
      'Início',
    ),
    _NavItem(
      '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20c.8-3.6 3.4-5.5 6.5-5.5s5.7 1.9 6.5 5.5"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14.8c2 .7 3.2 2.4 3.6 5.2"/>',
      'Comunidade',
    ),
    _NavItem(
      '<circle cx="12" cy="8" r="4"/><path d="M4 21c1-4 4.2-6 8-6s7 2 8 6"/>',
      'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset > 0 ? bottomInset : 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: EDColors.navy,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow( 
                  color: EDColors.ink.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _items.length; i++)
                  if (i == currentIndex)
                    // Só a aba ativa pode encolher (rótulo com reticências)
                    // para não estourar em telas estreitas.
                    Flexible(
                      child: _NavButton(
                        item: _items[i],
                        selected: true,
                        badge: i == 3 ? communityBadge : 0,
                        onTap: () => onTap(i),
                      ),
                    )
                  else
                    _NavButton(
                      item: _items[i],
                      selected: false,
                      badge: i == 3 ? communityBadge : 0,
                      onTap: () => onTap(i),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  static const _idleColor = Color(0xFFC3D6EF);

  @override
  Widget build(BuildContext context) {
    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.string(
          item.svg(selected ? 2.2 : 1.8),
          width: selected ? 20 : 24,
          height: selected ? 20 : 24,
          colorFilter: ColorFilter.mode(
            selected ? EDColors.ink : _idleColor,
            BlendMode.srcIn,
          ),
        ),
        if (badge > 0 && !selected)
          Positioned(
            top: -2,
            right: -3,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: EDColors.gold,
                shape: BoxShape.circle,
                border: Border.all(color: EDColors.ink, width: 1.5),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${item.label}, $badge novidades' : item.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            height: 48,
            width: selected ? null : 48,
            padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 0),
            // Sem alignment na aba ativa: com alignment o Container ocupa
            // todo o espaço livre da Row e a pílula estica.
            alignment: selected ? null : Alignment.center,
            decoration: ShapeDecoration(
              color: selected ? EDColors.gold : Colors.transparent,
              shape: const StadiumBorder(),
            ),
            child: selected
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconWidget,
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: EDText.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: EDColors.ink,
                          ),
                        ),
                      ),
                    ],
                  )
                : iconWidget,
          ),
        ),
      ),
    );
  }
}
