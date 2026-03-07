import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/widgets/comment_section.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.translate('deletePost')),
        content: Text(l.translate('deletePostConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.translate('delete'),
              style: const TextStyle(color: AppTheme.errorRed),
            ),
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
    final l = AppLocalizations.of(context);

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header - LinkedIn style
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile/${widget.post.authorId}'),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: widget.post.authorProfilePicture != null
                        ? NetworkImage(widget.post.authorProfilePicture!)
                        : null,
                    child: widget.post.authorProfilePicture == null
                        ? Text(
                            widget.post.authorName.isNotEmpty
                                ? widget.post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            context.push('/profile/${widget.post.authorId}'),
                        child: Text(
                          widget.post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        timeago.format(widget.post.createdAt),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.post.authorId == widget.currentUserId)
                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: AppTheme.errorRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(l.translate('delete')),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') _deletePost();
                    },
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              widget.post.content,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          // Tags
          if (widget.post.cropType != null || widget.post.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (widget.post.cropType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.post.cropType!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ...widget.post.tags.map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Images
          if (widget.post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
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
            ),
          // Engagement stats
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                if (_likeCount > 0) ...[
                  Icon(Icons.thumb_up, size: 14, color: AppTheme.primaryGreen),
                  const SizedBox(width: 4),
                  Text(
                    '$_likeCount',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const Spacer(),
                if (widget.post.commentCount > 0)
                  Text(
                    '${widget.post.commentCount} ${l.translate('comment').toLowerCase()}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),
          // Action buttons - LinkedIn style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleLike,
                    icon: Icon(
                      _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: _isLiked
                          ? AppTheme.primaryGreen
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    label: Text(
                      l.translate('like'),
                      style: TextStyle(
                        color: _isLiked
                            ? AppTheme.primaryGreen
                            : AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showComments = !_showComments),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    label: Text(
                      l.translate('comment'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Comments Section
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
