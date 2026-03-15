import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
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
  final _focusNode = FocusNode();
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
      }
    });
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
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    return Container(
      color: AppTheme.background,
      child: Column(
        children: [
          // Comment input - LinkedIn style (avatar + rounded input)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      AppTheme.primaryGreen.withValues(alpha: 0.1),
                  backgroundImage: currentUser?.profilePicture != null
                      ? NetworkImage(currentUser!.profilePicture!)
                      : null,
                  child: currentUser?.profilePicture == null
                      ? Text(
                          (currentUser?.name ?? 'U').isNotEmpty
                              ? (currentUser?.name ?? 'U')[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: l.translate('addComment'),
                              hintStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              counterText: '',
                            ),
                            maxLength: 1000,
                            maxLines: 3,
                            minLines: 1,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (_showEmoji) {
                              _focusNode.requestFocus();
                            } else {
                              _focusNode.unfocus();
                            }
                            setState(() => _showEmoji = !_showEmoji);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              _showEmoji
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions_outlined,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _addComment,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.send_rounded,
                        color: AppTheme.primaryGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Emoji picker for comments
          if (_showEmoji)
            SizedBox(
              height: 220,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _commentController.text += emoji.emoji;
                  _commentController.selection =
                      TextSelection.fromPosition(
                    TextPosition(
                        offset: _commentController.text.length),
                  );
                },
                onBackspacePressed: () {
                  final text = _commentController.text;
                  if (text.isNotEmpty) {
                    _commentController.text =
                        text.characters.skipLast(1).string;
                    _commentController.selection =
                        TextSelection.fromPosition(
                      TextPosition(
                          offset: _commentController.text.length),
                    );
                  }
                },
                config: Config(
                  height: 220,
                  checkPlatformCompatibility: false,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 24,
                    backgroundColor: AppTheme.background,
                  ),
                  searchViewConfig: SearchViewConfig(
                    backgroundColor: AppTheme.background,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    backgroundColor: AppTheme.background,
                    indicatorColor: AppTheme.primaryGreen,
                    iconColorSelected: AppTheme.primaryGreen,
                  ),
                  bottomActionBarConfig: const BottomActionBarConfig(
                    enabled: false,
                  ),
                ),
              ),
            ),

          // Comments list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (_comments.isNotEmpty)
            Container(
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              comment.authorProfilePicture != null
                                  ? NetworkImage(
                                      comment.authorProfilePicture!)
                                  : null,
                          backgroundColor: AppTheme.primaryGreen
                              .withValues(alpha: 0.1),
                          child: comment.authorProfilePicture == null
                              ? Text(
                                  comment.authorName.isNotEmpty
                                      ? comment.authorName[0]
                                          .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      timeago.format(comment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
