import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/crop_group_model.dart';
import 'package:soilsocial/services/group_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  final _groupService = GroupService();
  late TabController _tabController;
  List<CropGroupModel> _myGroups = [];
  List<CropGroupModel> _allGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final results = await Future.wait([
      _groupService.getUserGroups(uid),
      _groupService.getAllGroups(),
    ]);
    if (mounted) {
      setState(() {
        _myGroups = results[0];
        _allGroups = results[1];
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final l = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final cropController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l.translate('createGroup')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l.translate('groupName'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: l.translate('description'),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cropController,
                decoration: InputDecoration(labelText: l.translate('cropType')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: Text(l.translate('create')),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      await _groupService.createGroup(
        name: nameController.text.trim(),
        description: descController.text.trim(),
        cropType: cropController.text.trim(),
        userId: uid,
      );
      _loadGroups();
    }

    nameController.dispose();
    descController.dispose();
    cropController.dispose();
  }

  Future<void> _joinGroup(String groupId) async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    await _groupService.joinGroup(groupId, uid);
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('cropGroups')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: l.translate('myGroups')),
                    Tab(text: l.translate('discover')),
                  ],
                ),
              ),
              Container(color: AppTheme.dividerColor, height: 1),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupList(l, _myGroups, uid, isMember: true),
                _buildGroupList(l, _allGroups, uid, isMember: false),
              ],
            ),
    );
  }

  Widget _buildGroupList(
    AppLocalizations l,
    List<CropGroupModel> groups,
    String uid, {
    required bool isMember,
  }) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isMember
                  ? l.translate('noGroupsJoined')
                  : l.translate('noGroupsAvailable'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadGroups,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: groups.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final g = groups[index];
          final alreadyMember = g.members.any((m) => m.userId == uid);
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: const Icon(Icons.grass, color: AppTheme.primaryGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (g.cropType.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            g.cropType,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${g.members.length} ${l.translate('members')}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (g.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            g.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                alreadyMember
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          l.translate('joined'),
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () => _joinGroup(g.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(l.translate('join')),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
