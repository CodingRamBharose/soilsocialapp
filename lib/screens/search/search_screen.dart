import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/models/product_model.dart';
import 'package:soilsocial/models/event_model.dart';
import 'package:soilsocial/services/user_service.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/services/product_service.dart';
import 'package:soilsocial/services/event_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<UserModel> _users = [];
  List<PostModel> _posts = [];
  List<ProductModel> _products = [];
  List<EventModel> _events = [];
  bool _isSearching = false;
  String _query = '';

  final _userService = UserService();
  final _postService = PostService();
  final _productService = ProductService();
  final _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
        _products = [];
        _events = [];
        _query = '';
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _query = query;
    });

    final results = await Future.wait([
      _userService.searchUsers(query),
      _postService.searchPosts(query),
      _productService.searchProducts(query),
      _eventService.searchEvents(query),
    ]);

    if (mounted) {
      setState(() {
        _users = results[0] as List<UserModel>;
        _posts = results[1] as List<PostModel>;
        _products = results[2] as List<ProductModel>;
        _events = results[3] as List<EventModel>;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users, posts, products, events...',
            border: InputBorder.none,
          ),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _search('');
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'People (${_users.length})'),
            Tab(text: 'Posts (${_posts.length})'),
            Tab(text: 'Products (${_products.length})'),
            Tab(text: 'Events (${_events.length})'),
          ],
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _query.isEmpty
          ? const Center(child: Text('Search for anything'))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserResults(),
                _buildPostResults(),
                _buildProductResults(),
                _buildEventResults(),
              ],
            ),
    );
  }

  Widget _buildUserResults() {
    if (_users.isEmpty) return const Center(child: Text('No users found'));
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: u.profilePicture != null
                ? CachedNetworkImageProvider(u.profilePicture!)
                : null,
            child: u.profilePicture == null ? const Icon(Icons.person) : null,
          ),
          title: Text(u.name),
          subtitle: u.location != null ? Text(u.location!) : null,
          onTap: () => context.push('/user/${u.uid}'),
        );
      },
    );
  }

  Widget _buildPostResults() {
    if (_posts.isEmpty) return const Center(child: Text('No posts found'));
    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (_, i) {
        final p = _posts[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: p.authorProfilePicture != null
                ? CachedNetworkImageProvider(p.authorProfilePicture!)
                : null,
            child: p.authorProfilePicture == null
                ? const Icon(Icons.article)
                : null,
          ),
          title: Text(p.authorName),
          subtitle: Text(
            p.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {}, // Posts show inline
        );
      },
    );
  }

  Widget _buildProductResults() {
    if (_products.isEmpty)
      return const Center(child: Text('No products found'));
    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (_, i) {
        final p = _products[i];
        return ListTile(
          leading: p.images.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: p.images.first,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : const CircleAvatar(child: Icon(Icons.store)),
          title: Text(p.name),
          subtitle: Text(p.formattedPrice),
          onTap: () => context.push('/product/${p.id}'),
        );
      },
    );
  }

  Widget _buildEventResults() {
    if (_events.isEmpty) return const Center(child: Text('No events found'));
    return ListView.builder(
      itemCount: _events.length,
      itemBuilder: (_, i) {
        final e = _events[i];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.event)),
          title: Text(e.title),
          subtitle: Text('${e.attendees.length} attending'),
          onTap: () => context.push('/event/${e.id}'),
        );
      },
    );
  }
}
