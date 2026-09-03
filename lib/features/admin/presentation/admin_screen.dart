import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme.dart';
import 'pages/admin_activities_page.dart';
import 'pages/admin_community_page.dart';
import 'pages/admin_config_page.dart';
import 'pages/admin_content_page.dart';
import 'pages/admin_notifications_page.dart';
import 'pages/admin_quizzes_page.dart';
import 'pages/admin_users_page.dart';

class _AdminColors {
  static const Color backgroundDark = Color(0xFF1E1E2C);
  static const Color surfaceDark = Color(0xFF272738);
  static const Color surfaceLightDark = Color(0xFF2F2F42);
  static const Color textPrimaryDark = Color(0xFFF0ECE3);
  static const Color textSecondaryDark = Color(0xFF9A96A6);
  static const Color dividerDark = Color(0xFF3A3A4E);

  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Color(0xFFFAF6EE);
  static const Color surfaceLightLight = Color(0xFFF5F0E5);
  static const Color textPrimaryLight = Color(0xFF3D3D3D);
  static const Color textSecondaryLight = Color(0xFF8A8A8A);
  static const Color dividerLight = Color(0xFFEEEEEE);

  static const Color accent = ElevaColors.gold;
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;
  bool _isDark = true;

  static const _drawerIcons = <IconData>[
    Icons.menu_book_rounded,
    Icons.quiz_rounded,
    Icons.task_alt_rounded,
    Icons.people_rounded,
    Icons.forum_rounded,
    Icons.settings_rounded,
    Icons.notifications_rounded,
  ];

  static const _drawerLabels = <String>[
    'Conteudo',
    'Quizzes',
    'Atividades',
    'Usuarios',
    'Comunidade',
    'Configuracoes',
    'Notificacoes',
  ];

  final _pages = const [
    AdminContentPage(),
    AdminQuizzesPage(),
    AdminActivitiesPage(),
    AdminUsersPage(),
    AdminCommunityPage(),
    AdminConfigPage(),
    AdminNotificationsPage(),
  ];

  void _onSelectPage(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context);
  }

  Color get _bg =>
      _isDark ? _AdminColors.backgroundDark : _AdminColors.backgroundLight;
  Color get _surface =>
      _isDark ? _AdminColors.surfaceDark : _AdminColors.surfaceLight;
  Color get _surfaceAlt =>
      _isDark ? _AdminColors.surfaceLightDark : _AdminColors.surfaceLightLight;
  Color get _textPrimary =>
      _isDark ? _AdminColors.textPrimaryDark : _AdminColors.textPrimaryLight;
  Color get _textSecondary =>
      _isDark ? _AdminColors.textSecondaryDark : _AdminColors.textSecondaryLight;
  Color get _divider =>
      _isDark ? _AdminColors.dividerDark : _AdminColors.dividerLight;

  ThemeData get _currentTheme => ThemeData(
        useMaterial3: true,
        brightness: _isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ElevaColors.gold,
          brightness: _isDark ? Brightness.dark : Brightness.light,
          primary: ElevaColors.gold,
          onPrimary: Colors.white,
          surface: _surface,
          onSurface: _textPrimary,
          onSurfaceVariant: _textSecondary,
          surfaceContainerHighest: _surfaceAlt,
        ),
        scaffoldBackgroundColor: _bg,
        appBarTheme: AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _textPrimary,
          elevation: 0,
        ),
        cardColor: _surface,
        dividerColor: _divider,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: ElevaColors.gold,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: ElevaColors.gold, width: 1.5),
          ),
          hintStyle: TextStyle(color: _textSecondary),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: _textSecondary,
          dividerColor: Colors.transparent,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _currentTheme,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: _textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _AdminColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                _drawerLabels[_currentIndex],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        drawer: Drawer(
          backgroundColor: _bg,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _divider, width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _surfaceAlt,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  'assets/images/logo_icon.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: _surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => _isDark = !_isDark),
                              icon: Icon(
                                _isDark
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                color: _AdminColors.accent,
                                size: 22,
                              ),
                              tooltip: _isDark ? 'Tema claro' : 'Tema escuro',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Painel Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Eleva App',
                        style: TextStyle(
                          fontSize: 13,
                          color: _AdminColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(_drawerLabels.length, (i) {
                  final isSelected = _currentIndex == i;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    child: Material(
                      color: isSelected
                          ? _AdminColors.accent.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        splashColor:
                            _AdminColors.accent.withValues(alpha: 0.1),
                        onTap: () => _onSelectPage(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(
                                _drawerIcons[i],
                                size: 22,
                                color: isSelected
                                    ? _AdminColors.accent
                                    : _textPrimary,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                _drawerLabels[i],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _AdminColors.accent
                                      : _textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: _AdminColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Divider(
                    height: 1, indent: 20, endIndent: 20, color: _divider),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Supabase.instance.client.auth.signOut(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded,
                                size: 22, color: Colors.redAccent),
                            SizedBox(width: 14),
                            Text(
                              'Sair',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
    );
  }
}
