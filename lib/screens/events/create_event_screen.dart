import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/event_model.dart';
import 'package:soilsocial/services/event_service.dart';
import 'package:soilsocial/services/storage_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _tagController = TextEditingController();
  final _eventService = EventService();
  final _storageService = StorageService();

  EventType _eventType = EventType.workshop;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  final List<String> _tags = [];
  File? _imageFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _maxAttendeesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _startDate : _endDate),
    );
    if (time == null) return;

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startDate = dt;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(hours: 2));
        }
      } else {
        _endDate = dt;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel!;

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _storageService.uploadEventImage(_imageFile!);
    }

    final event = EventModel(
      id: '',
      organizerId: user.uid,
      organizerName: user.name,
      organizerProfilePicture: user.profilePicture,
      eventType: _eventType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      startDate: _startDate,
      endDate: _endDate,
      maxAttendees: _maxAttendeesController.text.isNotEmpty
          ? int.tryParse(_maxAttendeesController.text)
          : null,
      tags: _tags,
      imageUrl: imageUrl,
    );

    await _eventService.createEvent(event);
    if (mounted) {
      setState(() => _isSaving = false);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<EventType>(
                initialValue: _eventType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: EventType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(EventModel.eventTypeLabel(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Location/Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              // Start date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date & Time'),
                subtitle: Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year} at ${_startDate.hour}:${_startDate.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _pickDate(true),
              ),
              // End date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('End Date & Time'),
                subtitle: Text(
                  '${_endDate.day}/${_endDate.month}/${_endDate.year} at ${_endDate.hour}:${_endDate.minute.toString().padLeft(2, '0')}',
                ),
                onTap: () => _pickDate(false),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxAttendeesController,
                decoration: const InputDecoration(
                  labelText: 'Max Attendees (optional)',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
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
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  IconButton(onPressed: _addTag, icon: const Icon(Icons.add)),
                ],
              ),
              const SizedBox(height: 16),
              // Image
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_imageFile == null ? 'Add Image' : 'Change Image'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Event'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
