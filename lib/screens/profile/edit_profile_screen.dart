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
  final _farmSizeController = TextEditingController();
  final _farmingExperienceController = TextEditingController();
  final _cropController = TextEditingController();
  final _techniqueController = TextEditingController();
  List<String> _cropsGrown = [];
  List<String> _farmingTechniques = [];
  String? _farmingType;
  bool _isSaving = false;
  File? _imageFile;

  static const List<String> _farmingTypes = [
    'Organic',
    'Traditional',
    'Mixed',
    'Hydroponic',
    'Dairy',
    'Poultry',
    'Horticulture',
    'Floriculture',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _nameController.text = user.name;
      _locationController.text = user.location ?? '';
      _bioController.text = user.bio ?? '';
      _farmSizeController.text = user.farmSize ?? '';
      _farmingExperienceController.text = user.farmingExperience ?? '';
      _farmingType = user.farmingType;
      _cropsGrown = List.from(user.cropsGrown);
      _farmingTechniques = List.from(user.farmingTechniques);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _farmSizeController.dispose();
    _farmingExperienceController.dispose();
    _cropController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
    );
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
      profilePictureUrl = await _storageService.uploadProfilePicture(
        _imageFile!,
        uid,
      );
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'bio': _bioController.text.trim(),
      'farmSize': _farmSizeController.text.trim(),
      'farmingExperience': _farmingExperienceController.text.trim(),
      'farmingType': _farmingType ?? '',
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

  Widget _buildChipList({
    required List<String> items,
    required void Function(String) onRemove,
  }) {
    return Wrap(
      spacing: 8,
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onRemove(item),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAddRow({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onAdd,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
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
              // Profile Picture
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
                    child:
                        _imageFile == null && user?.profilePicture == null
                            ? const Icon(
                                Icons.camera_alt,
                                size: 36,
                                color: AppTheme.primaryGreen,
                              )
                            : null,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    l.translate('changePhoto'),
                    style: const TextStyle(color: AppTheme.primaryGreen),
                  ),
                ),
              ),

              // Basic Info
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l.translate('name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
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
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: l.translate('bio'),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 300,
              ),

              // Farm Details Section
              _buildSectionHeader(l.translate('farmDetails')),
              const SizedBox(height: 8),
              TextFormField(
                controller: _farmSizeController,
                decoration: InputDecoration(
                  labelText: l.translate('farmSize'),
                  hintText: 'e.g., 5 acres',
                  prefixIcon: const Icon(Icons.landscape_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _farmingExperienceController,
                decoration: InputDecoration(
                  labelText: l.translate('farmingExperience'),
                  hintText: 'e.g., 10 years',
                  prefixIcon: const Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _farmingType,
                decoration: InputDecoration(
                  labelText: l.translate('farmingType'),
                  prefixIcon: const Icon(Icons.agriculture),
                ),
                items: _farmingTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _farmingType = v),
              ),

              // Crops Grown
              const SizedBox(height: 24),
              Text(
                l.translate('cropsGrown'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildChipList(
                items: _cropsGrown,
                onRemove: (c) => setState(() => _cropsGrown.remove(c)),
              ),
              _buildAddRow(
                controller: _cropController,
                hint: l.translate('addACrop'),
                onAdd: _addCrop,
              ),

              // Farming Techniques
              const SizedBox(height: 16),
              Text(
                l.translate('farmingTechniques'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildChipList(
                items: _farmingTechniques,
                onRemove: (t) =>
                    setState(() => _farmingTechniques.remove(t)),
              ),
              _buildAddRow(
                controller: _techniqueController,
                hint: l.translate('addATechnique'),
                onAdd: _addTechnique,
              ),

              // Save Button
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.translate('saveChanges')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
