import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/services/storage_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _cropTypeController = TextEditingController();
  final _tagController = TextEditingController();
  final _postService = PostService();
  final _storageService = StorageService();
  final List<File> _images = [];
  final List<String> _tags = [];
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _cropTypeController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(maxWidth: 1024);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked.map((x) => File(x.path))));
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  Future<void> _createPost() async {
    final l = AppLocalizations.of(context);
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.translate('pleaseWriteSomething'))));
      return;
    }

    setState(() => _isPosting = true);
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel!;

    List<String> imageUrls = [];
    if (_images.isNotEmpty) {
      imageUrls = await _storageService.uploadMultipleImages(_images, 'posts');
    }

    final post = PostModel(
      id: '',
      content: content,
      images: imageUrls,
      authorId: user.uid,
      authorName: user.name,
      authorProfilePicture: user.profilePicture,
      cropType: _cropTypeController.text.trim().isNotEmpty
          ? _cropTypeController.text.trim()
          : null,
      tags: _tags,
    );

    await _postService.createPost(post);
    if (mounted) {
      setState(() => _isPosting = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('createPost')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: FilledButton(
              onPressed: _isPosting ? null : _createPost,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: _isPosting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.translate('post')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: l.translate('whatsHappeningFarm'),
                  hintStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
              ),
            ),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _cropTypeController,
                decoration: InputDecoration(
                  hintText: l.translate('cropTypeOptional'),
                  prefixIcon: const Icon(Icons.grass, color: AppTheme.primaryGreen),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Divider(height: 1),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: _tags
                          .map((t) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(t,
                                        style: const TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontSize: 13)),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _tags.remove(t)),
                                      child: const Icon(Icons.close,
                                          size: 14,
                                          color: AppTheme.primaryGreen),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            hintText: l.translate('addTags'),
                            prefixIcon: const Icon(Icons.tag,
                                color: AppTheme.textSecondary),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _addTag(),
                        ),
                      ),
                      IconButton(
                          onPressed: _addTag,
                          icon: const Icon(Icons.add,
                              color: AppTheme.primaryGreen)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_images.isNotEmpty)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) => Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_images[index],
                                height: 120, width: 120, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _images.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: Text(l.translate('addImages')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: const BorderSide(color: AppTheme.primaryGreen),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
