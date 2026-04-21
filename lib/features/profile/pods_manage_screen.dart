import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pod_preset.dart';
import '../../core/persistence/pod_repository.dart';
import '../../core/persistence/providers.dart';
import '../../ui/theme/app_color_tokens.dart';
import '../../ui/tokens/layout_tokens.dart';
import '../../ui/tokens/radius_tokens.dart';

class PodsManageScreen extends ConsumerStatefulWidget {
  const PodsManageScreen({super.key});

  @override
  ConsumerState<PodsManageScreen> createState() => _PodsManageScreenState();
}

class _PodsManageScreenState extends ConsumerState<PodsManageScreen> {
  List<PodPreset> _pods = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _pods = ref.read(podRepositoryProvider).getAll();
    });
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t.toUpperCase();
  }

  Future<void> _editPod(PodRepository repo, PodPreset? existing) async {
    final result = await showDialog<({String name, List<String> members})?>(
      context: context,
      builder: (ctx) => _PodEditorDialog(
        initialName: existing?.name ?? '',
        initialMembers: existing != null
            ? List<String>.from(existing.memberPlayerIds)
            : [],
      ),
    );

    if (result == null || !mounted) return;

    if (existing == null) {
      await repo.save(
        PodPreset.create(
          name: result.name,
          memberPlayerIds: result.members,
        ),
      );
    } else {
      existing.name = result.name;
      existing.memberPlayerIds = result.members;
      await repo.save(existing);
    }

    bumpPodPresetsRevision(ref);
    _reload();
  }

  Future<void> _confirmDelete(PodRepository repo, PodPreset pod) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pod?'),
        content: Text('Remove “${pod.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.delete(pod.id);
      bumpPodPresetsRevision(ref);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);
    final repo = ref.read(podRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('My pods'),
        backgroundColor: colors.backgroundPrimary,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(LayoutTokens.gr3),
        itemCount: _pods.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: LayoutTokens.gr2),
              child: Text(
                'Create a pod with a name and the player names you play with. '
                'Select it in the host lobby when you set up a match.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            );
          }
          final pod = _pods[i - 1];
          final n = pod.memberPlayerIds.length;
          return Card(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.md),
            ),
            child: ExpansionTile(
              title: Text(
                pod.name,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                n == 0 ? 'No players yet' : '$n player${n == 1 ? '' : 's'}',
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
              children: [
                if (pod.memberPlayerIds.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      LayoutTokens.gr3,
                      0,
                      LayoutTokens.gr3,
                      LayoutTokens.gr2,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Add players when you edit this pod.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      LayoutTokens.gr2,
                      0,
                      LayoutTokens.gr2,
                      LayoutTokens.gr2,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pod.memberPlayerIds.map((id) {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor:
                                colors.primaryAccent.withValues(alpha: 0.35),
                            child: Text(
                              _initials(id),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          label: Text(
                            id,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                          backgroundColor: colors.backgroundSecondary,
                          side: BorderSide(
                            color: colors.textSecondary.withValues(alpha: 0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _editPod(repo, pod),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(repo, pod),
                      color: colors.primaryAccent,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editPod(repo, null),
        icon: const Icon(Icons.add),
        label: const Text('Add pod'),
      ),
    );
  }
}

class _PodEditorDialog extends StatefulWidget {
  final String initialName;
  final List<String> initialMembers;

  const _PodEditorDialog({
    required this.initialName,
    required this.initialMembers,
  });

  @override
  State<_PodEditorDialog> createState() => _PodEditorDialogState();
}

class _PodEditorDialogState extends State<_PodEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addCtrl;
  late List<String> _members;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _addCtrl = TextEditingController();
    _members = List<String>.from(widget.initialMembers);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addCtrl.dispose();
    super.dispose();
  }

  void _addMember() {
    final raw = _addCtrl.text.trim();
    if (raw.isEmpty) return;
    final lower = raw.toLowerCase();
    if (_members.any((m) => m.toLowerCase() == lower)) {
      _addCtrl.clear();
      return;
    }
    setState(() {
      _members.add(raw);
      _addCtrl.clear();
    });
  }

  void _removeMember(String id) {
    setState(() => _members.remove(id));
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorTokens.of(context);

    return AlertDialog(
      title: Text(widget.initialName.isEmpty ? 'New pod' : 'Edit pod'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pod name',
                  hintText: 'e.g. Friday Night Commander',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: LayoutTokens.gr3),
              Text(
                'Players',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: LayoutTokens.gr1),
              Text(
                'Use the same names players use in the app (their profile name).',
                style: TextStyle(color: colors.textSecondary, fontSize: 11),
              ),
              SizedBox(height: LayoutTokens.gr2),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Player name',
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  IconButton(
                    onPressed: _addMember,
                    icon: const Icon(Icons.person_add_outlined),
                    tooltip: 'Add player',
                  ),
                ],
              ),
              SizedBox(height: LayoutTokens.gr1),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _members.map((id) {
                  return InputChip(
                    label: Text(id),
                    onDeleted: () => _removeMember(id),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, (name: name, members: List<String>.from(_members)));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
