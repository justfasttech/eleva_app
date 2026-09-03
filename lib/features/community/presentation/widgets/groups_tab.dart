import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../models/community_group.dart';
import '../../providers/groups_provider.dart';
import '../group_detail_page.dart';

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final ownsGroup = ref.watch(userOwnsGroupProvider).value ?? false;

    return Column(
      children: [
        if (!ownsGroup)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: ElevaColors.offWhite,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _showCreateGroup(context, ref),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 20, color: ElevaColors.gold),
                      SizedBox(width: 12),
                      Text(
                        'Criar novo grupo',
                        style: TextStyle(
                          fontSize: 14,
                          color: ElevaColors.gold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: groupsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: ElevaColors.gold),
            ),
            error: (e, _) => Center(
              child: Text('Erro: $e',
                  style: const TextStyle(color: ElevaColors.textMuted)),
            ),
            data: (groups) {
              if (groups.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum grupo ainda.\nCrie o primeiro!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14, color: ElevaColors.textMuted),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _GroupCard(group: groups[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateGroup(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CreateGroupSheet(),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o nome do grupo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      final result = await Supabase.instance.client
          .from('groups')
          .insert({
            'creator_id': userId,
            'name': name,
            'description': _descController.text.trim(),
            'icon_name': 'groups_rounded',
          })
          .select('id')
          .single();

      await Supabase.instance.client.from('group_members').insert({
        'group_id': result['id'],
        'user_id': userId,
      });

      ref.invalidate(userOwnsGroupProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Grupo criado!'),
            backgroundColor: ElevaColors.gold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('groups_one_per_creator')
            ? 'Você já possui um grupo. Cada usuário pode criar apenas um grupo.'
            : 'Erro ao criar: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ElevaColors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Criar grupo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ElevaColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Nome do grupo'),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(hintText: 'Descrição'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : _create,
            child: _isSaving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: ElevaColors.white,
                    ),
                  )
                : const Text('Criar grupo'),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final CommunityGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships =
        ref.watch(userGroupMembershipsProvider).value ?? {};
    final isMember = memberships.contains(group.id);

    return GestureDetector(
      onTap: () async {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('name')
            .eq('id', group.creatorId)
            .maybeSingle();
        final creatorName = profile?['name'] as String? ?? 'Desconhecido';

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupDetailPage(
                group: group,
                creatorName: creatorName,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ElevaColors.offWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [ElevaColors.gold, ElevaColors.goldLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(group.icon, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ElevaColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              size: 14, color: ElevaColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${group.membersCount} membros',
                            style: const TextStyle(
                                fontSize: 12, color: ElevaColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ElevaColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Membro',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ElevaColors.gold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: ElevaColors.textMuted),
              ],
            ),
            if (group.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                group.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: ElevaColors.textMuted,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
