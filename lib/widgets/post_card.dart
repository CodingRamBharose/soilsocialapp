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
  int _currentImageIndex = 0;

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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () =>
                      context.push('/profile/${widget.post.authorId}'),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    backgroundImage:
                        widget.post.authorProfilePicture != null
                            ? NetworkImage(
                                widget.post.authorProfilePicture!)
                            : null,
                    child: widget.post.authorProfilePicture == null
                        ? Text(
                            widget.post.authorName.isNotEmpty
                                ? widget.post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        context.push('/profile/${widget.post.authorId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              timeago.format(widget.post.createdAt),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.public,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.post.authorId == widget.currentUserId)
                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppTheme.textSecondary,
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(
                widget.post.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
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
                        color:
                            AppTheme.primaryGreen.withValues(alpha: 0.08),
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
                        color: AppTheme.primaryGreen.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Images - Full width, LinkedIn-style
          if (widget.post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildImageSection(),
            ),

          // Engagement stats row
          if (_likeCount > 0 || widget.post.commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  if (_likeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.thumb_up,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
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
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showComments = !_showComments),
                      child: Text(
                        '${widget.post.commentCount} ${l.translate('comment').toLowerCase()}${widget.post.commentCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Divider before action buttons
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Divider(height: 1, indent: 16, endIndent: 16),
          ),

          // Action buttons - LinkedIn style
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            color: _isLiked
                                ? AppTheme.primaryGreen
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.translate('like'),
                            style: TextStyle(
                              color: _isLiked
                                  ? AppTheme.primaryGreen
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        setState(() => _showComments = !_showComments),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.translate('comment'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.share_outlined,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.translate('share'),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildImageSection() {
    final images = widget.post.images;

    if (images.length == 1) {
      // Single image - full width
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SizedBox(
          width: double.infinity,
          child: Image.network(
            images[0],
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 250,
                color: AppTheme.background,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Multiple images - page view with indicators
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemBuilder: (context, index) => SizedBox(
              width: double.infinity,
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppTheme.background,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                ...List.generate(
                  images.length,
                  (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentImageIndex
                          ? AppTheme.primaryGreen
                          : AppTheme.cardBorder,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
