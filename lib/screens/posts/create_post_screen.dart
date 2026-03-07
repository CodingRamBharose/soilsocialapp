import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/services/post_service.dart';
import 'package:soilsocial/services/storage_service.dart';

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
      setState(() {
        _images.addAll(picked.map((x) => File(x.path)));
      });
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
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write something')));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _createPost,
            child: _isPosting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              maxLength: 2000,
              decoration: const InputDecoration(
                hintText: "What's happening on your farm?",
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const Divider(),
            TextField(
              controller: _cropTypeController,
              decoration: const InputDecoration(
                hintText: 'Crop type (optional)',
                prefixIcon: Icon(Icons.grass),
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            // Tags
            Wrap(
              spacing: 8,
              children: _tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                  )
                  .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Add tags...',
                      prefixIcon: Icon(Icons.tag),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
              ],
            ),
            const Divider(),
            // Images
            if (_images.isNotEmpty)
              SizedBox(
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
                          child: Image.file(
                            _images[index],
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.image),
              label: const Text('Add Images'),
            ),
          ],
        ),
      ),
    );
  }
}
