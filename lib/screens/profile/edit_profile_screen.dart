import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/services/user_service.dart';
import 'package:soilsocial/services/storage_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _cropController = TextEditingController();
  final _techniqueController = TextEditingController();
  List<String> _cropsGrown = [];
  List<String> _farmingTechniques = [];
  bool _isSaving = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _nameController.text = user.name;
      _locationController.text = user.location ?? '';
      _bioController.text = user.bio ?? '';
      _cropsGrown = List.from(user.cropsGrown);
      _farmingTechniques = List.from(user.farmingTechniques);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _cropController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _addCrop() {
    final crop = _cropController.text.trim();
    if (crop.isNotEmpty && !_cropsGrown.contains(crop)) {
      setState(() => _cropsGrown.add(crop));
      _cropController.clear();
    }
  }

  void _addTechnique() {
    final technique = _techniqueController.text.trim();
    if (technique.isNotEmpty && !_farmingTechniques.contains(technique)) {
      setState(() => _farmingTechniques.add(technique));
      _techniqueController.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.firebaseUser!.uid;

    String? profilePictureUrl;
    if (_imageFile != null) {
      profilePictureUrl =
          await _storageService.uploadProfilePicture(_imageFile!, uid);
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'cropsGrown': _cropsGrown,
      'farmingTechniques': _farmingTechniques,
    };
    if (profilePictureUrl != null) {
      data['profilePicture'] = profilePictureUrl;
    }

    await _userService.updateProfile(uid, data);
    await authProvider.refreshUserProfile();

    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final user = context.read<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('editProfile')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.1),
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (user?.profilePicture != null
                            ? NetworkImage(user!.profilePicture!)
                            : null),
                    child: _imageFile == null && user?.profilePicture == null
                        ? const Icon(Icons.camera_alt,
                            size: 36, color: AppTheme.primaryGreen)
                        : null,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: Text(l.translate('changePhoto'),
                      style: const TextStyle(color: AppTheme.primaryGreen)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l.translate('name')),
                validator: (v) => v == null || v.isEmpty
                    ? l.translate('nameRequired')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l.translate('location'),
                  hintText: l.translate('locationHint'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(labelText: l.translate('bio')),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              Text(l.translate('cropsGrown'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _cropsGrown
                    .map((c) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c,
                                  style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 13)),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _cropsGrown.remove(c)),
                                child: const Icon(Icons.close,
                                    size: 14, color: AppTheme.primaryGreen),
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
                      controller: _cropController,
                      decoration:
                          InputDecoration(hintText: l.translate('addACrop')),
                      onSubmitted: (_) => _addCrop(),
                    ),
                  ),
                  IconButton(
                      onPressed: _addCrop,
                      icon: const Icon(Icons.add,
                          color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 16),
              Text(l.translate('farmingTechniques'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _farmingTechniques
                    .map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
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
                                onTap: () => setState(
                                    () => _farmingTechniques.remove(t)),
                                child: const Icon(Icons.close,
                                    size: 14, color: AppTheme.primaryGreen),
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
                      controller: _techniqueController,
                      decoration: InputDecoration(
                          hintText: l.translate('addATechnique')),
                      onSubmitted: (_) => _addTechnique(),
                    ),
                  ),
                  IconButton(
                      onPressed: _addTechnique,
                      icon: const Icon(Icons.add,
                          color: AppTheme.primaryGreen)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l.translate('saveChanges')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
