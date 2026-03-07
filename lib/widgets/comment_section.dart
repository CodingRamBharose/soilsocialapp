import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:soilsocial/models/comment_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/providers/auth_provider.dart';

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
    return Column(
      children: [
        const Divider(),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.authorProfilePicture != null
                      ? NetworkImage(comment.authorProfilePicture!)
                      : null,
                  child: comment.authorProfilePicture == null
                      ? Text(
                          comment.authorName.isNotEmpty
                              ? comment.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
                title: Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                subtitle: Text(
                  comment.content,
                  style: const TextStyle(fontSize: 13),
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
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    contentPadding: EdgeInsets.symmetric(
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
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
