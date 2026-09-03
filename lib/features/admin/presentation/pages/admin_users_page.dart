import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


final _allProfilesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows);
});

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profilesAsync = ref.watch(_allProfilesProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Usuários', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
                ),
                profilesAsync.when(
                  data: (users) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${users.length} usuários', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              style: TextStyle(color: cs.onSurface),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar usuário...',
                prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surface,
              ),
            ),
          ),
          const SizedBox(height: 16),
          profilesAsync.when(
            loading: () => const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Expanded(
              child: Center(child: Text('Erro: $e')),
            ),
            data: (allUsers) {
              final filtered = _search.isEmpty
                  ? allUsers
                  : allUsers.where((u) {
                      final name = (u['name'] as String? ?? '').toLowerCase();
                      final email = (u['email'] as String? ?? '').toLowerCase();
                      return name.contains(_search) || email.contains(_search);
                    }).toList();

              final total = allUsers.length;
              final premium = allUsers.where((u) => u['subscription_status'] == 'premium').length;
              final free = total - premium;

              return Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          _StatCard(label: 'Total', value: '$total', icon: Icons.people_rounded),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Premium', value: '$premium', icon: Icons.star_rounded),
                          const SizedBox(width: 12),
                          _StatCard(label: 'Free', value: '$free', icon: Icons.person_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final user = filtered[i];
                          final name = user['name'] as String? ?? 'Sem nome';
                          final email = user['email'] as String? ?? '';
                          final faith = (user['faith_level'] as num?)?.toDouble() ?? 0.0;
                          final status = user['subscription_status'] as String? ?? 'free';
                          final avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: cs.primary.withValues(alpha: 0.15),
                                  child: Text(avatar, style: TextStyle(
                                      fontWeight: FontWeight.w600, color: cs.primary)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: TextStyle(
                                          fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                      const SizedBox(height: 2),
                                      Text(email, style: TextStyle(
                                          fontSize: 12, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.local_fire_department_rounded,
                                            size: 14, color: cs.primary),
                                        const SizedBox(width: 2),
                                        Text('$faith pts', style: TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status == 'premium'
                                            ? cs.primary
                                            : cs.onSurfaceVariant.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status == 'premium' ? 'Premium' : 'Free',
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.w600,
                                          color: status == 'premium'
                                              ? Colors.white : cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
