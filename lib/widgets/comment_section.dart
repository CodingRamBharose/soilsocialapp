import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:soilsocial/models/comment_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final String currentUserId;

  const CommentSection({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.currentUserId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final PostService _postService = PostService();
  final _commentController = TextEditingController();
  List<CommentModel> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      _comments = await _postService.getComments(widget.postId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    final comment = CommentModel(
      id: '',
      content: text,
      authorId: widget.currentUserId,
      authorName: user?.name ?? 'User',
      authorProfilePicture: user?.profilePicture,
      postId: widget.postId,
    );

    _commentController.clear();
    await _postService.addComment(comment, widget.postAuthorId);
    await _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Column(
      children: [
        Container(height: 1, color: AppTheme.dividerColor),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: AppTheme.dividerColor),
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: comment.authorProfilePicture != null
                          ? NetworkImage(comment.authorProfilePicture!)
                          : null,
                      backgroundColor:
                          AppTheme.primaryGreen.withValues(alpha: 0.1),
                      child: comment.authorProfilePicture == null
                          ? Text(
                              comment.authorName.isNotEmpty
                                  ? comment.authorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                comment.authorName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppTheme.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeago.format(comment.createdAt),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment.content,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: l.translate('addComment'),
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  maxLength: 1000,
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              IconButton(
                onPressed: _addComment,
                icon: const Icon(Icons.send),
                color: AppTheme.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
