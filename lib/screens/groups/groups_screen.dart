import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/crop_group_model.dart';
import 'package:soilsocial/services/group_service.dart';

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
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final cropController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: cropController,
                decoration: const InputDecoration(labelText: 'Crop Type'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
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
    final uid = context.read<AuthProvider>().firebaseUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Groups'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGroup,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupList(_myGroups, uid, isMember: true),
                _buildGroupList(_allGroups, uid, isMember: false),
              ],
            ),
    );
  }

  Widget _buildGroupList(
    List<CropGroupModel> groups,
    String uid, {
    required bool isMember,
  }) {
    if (groups.isEmpty) {
      return Center(
        child: Text(
          isMember
              ? 'You haven\'t joined any groups yet'
              : 'No groups available',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final g = groups[index];
          final alreadyMember = g.members.any((m) => m.userId == uid);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(Icons.grass),
              ),
              title: Text(
                g.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (g.cropType.isNotEmpty)
                    Text(
                      g.cropType,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Text('${g.members.length} members'),
                  if (g.description.isNotEmpty)
                    Text(
                      g.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              isThreeLine: true,
              trailing: alreadyMember
                  ? const Chip(
                      label: Text('Joined', style: TextStyle(fontSize: 12)),
                    )
                  : TextButton(
                      onPressed: () => _joinGroup(g.id),
                      child: const Text('Join'),
                    ),
            ),
          );
        },
      ),
    );
  }
}
