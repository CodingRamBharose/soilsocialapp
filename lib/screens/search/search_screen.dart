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
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l.translate('searchPlaceholder'),
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 20),
            ),
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
              onPressed: () {
                _searchController.clear();
                _search('');
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '${l.translate('people')} (${_users.length})'),
                  Tab(text: '${l.translate('posts')} (${_posts.length})'),
                  Tab(text: '${l.translate('products')} (${_products.length})'),
                  Tab(text: '${l.translate('events')} (${_events.length})'),
                ],
                labelStyle: const TextStyle(fontSize: 12),
              ),
              Container(color: AppTheme.dividerColor, height: 1),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _query.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(l.translate('searchAnything'),
                          style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserResults(l),
                    _buildPostResults(l),
                    _buildProductResults(l),
                    _buildEventResults(l),
                  ],
                ),
    );
  }

  Widget _buildUserResults(AppLocalizations l) {
    if (_users.isEmpty) {
      return Center(child: Text(l.translate('noUsersFound'),
          style: const TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final u = _users[i];
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: u.profilePicture != null
                  ? CachedNetworkImageProvider(u.profilePicture!)
                  : null,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: u.profilePicture == null
                  ? const Icon(Icons.person, color: AppTheme.primaryGreen)
                  : null,
            ),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            subtitle: u.location != null
                ? Text(u.location!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                : null,
            onTap: () => context.push('/user/${u.uid}'),
          ),
        );
      },
    );
  }

  Widget _buildPostResults(AppLocalizations l) {
    if (_posts.isEmpty) {
      return Center(child: Text(l.translate('noPostsFound'),
          style: const TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = _posts[i];
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: p.authorProfilePicture != null
                  ? CachedNetworkImageProvider(p.authorProfilePicture!)
                  : null,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: p.authorProfilePicture == null
                  ? const Icon(Icons.article, color: AppTheme.primaryGreen)
                  : null,
            ),
            title: Text(p.authorName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            subtitle: Text(p.content, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ),
        );
      },
    );
  }

  Widget _buildProductResults(AppLocalizations l) {
    if (_products.isEmpty) {
      return Center(child: Text(l.translate('noProductsFound'),
          style: const TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      itemCount: _products.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = _products[i];
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: p.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: p.images.first,
                      width: 50, height: 50, fit: BoxFit.cover,
                    ),
                  )
                : CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: const Icon(Icons.storefront, color: AppTheme.primaryGreen),
                  ),
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            subtitle: Text(p.formattedPrice,
                style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13)),
            onTap: () => context.push('/product/${p.id}'),
          ),
        );
      },
    );
  }

  Widget _buildEventResults(AppLocalizations l) {
    if (_events.isEmpty) {
      return Center(child: Text(l.translate('noEventsFound'),
          style: const TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.separated(
      itemCount: _events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = _events[i];
        return Container(
          color: Colors.white,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: const Icon(Icons.event, color: AppTheme.primaryGreen),
            ),
            title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            subtitle: Text('${e.attendees.length} ${l.translate('attending')}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            onTap: () => context.push('/event/${e.id}'),
          ),
        );
      },
    );
  }
}
