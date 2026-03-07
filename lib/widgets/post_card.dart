import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/widgets/comment_section.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onRefresh;
  final bool showDeleteOption;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.onRefresh,
    this.showDeleteOption = false,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  late bool _isLiked;
  late int _likeCount;
  bool _showComments = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.likes.contains(widget.currentUserId);
    _likeCount = widget.post.likes.length;
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    await _postService.toggleLike(
      widget.post.id,
      widget.currentUserId,
      widget.post.authorId,
    );
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _postService.deletePost(widget.post.id);
      widget.onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.post.authorProfilePicture != null
                  ? NetworkImage(widget.post.authorProfilePicture!)
                  : null,
              child: widget.post.authorProfilePicture == null
                  ? Text(
                      widget.post.authorName.isNotEmpty
                          ? widget.post.authorName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            title: GestureDetector(
              onTap: () => context.push('/profile/${widget.post.authorId}'),
              child: Text(
                widget.post.authorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            subtitle: Text(timeago.format(widget.post.createdAt)),
            trailing: widget.post.authorId == widget.currentUserId
                ? PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') _deletePost();
                    },
                  )
                : null,
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.post.content),
          ),
          // Tags
          if (widget.post.cropType != null || widget.post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 4,
                children: [
                  if (widget.post.cropType != null)
                    Chip(
                      label: Text(
                        widget.post.cropType!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.1,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ...widget.post.tags.map(
                    (tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          // Images
          if (widget.post.images.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.post.images.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.post.images[index],
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                    size: 20,
                  ),
                  label: Text('$_likeCount'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showComments = !_showComments),
                  icon: const Icon(Icons.comment_outlined, size: 20),
                  label: Text('${widget.post.commentCount}'),
                ),
              ],
            ),
          ),
          // Comments
          if (_showComments)
            CommentSection(
              postId: widget.post.id,
              postAuthorId: widget.post.authorId,
              currentUserId: widget.currentUserId,
            ),
        ],
      ),
    );
  }
}
