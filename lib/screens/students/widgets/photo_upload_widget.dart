/// EduX School Management System
/// Photo Upload Widget - Image picker with preview and crop
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Widget for uploading and previewing photos
class PhotoUploadWidget extends StatefulWidget {
  final Uint8List? initialPhoto;
  final ValueChanged<Uint8List?> onPhotoChanged;
  final double size;
  final bool enabled;

  const PhotoUploadWidget({
    super.key,
    this.initialPhoto,
    required this.onPhotoChanged,
    this.size = 120,
    this.enabled = true,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  Uint8List? _currentPhoto;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentPhoto = widget.initialPhoto;
  }

  @override
  void didUpdateWidget(PhotoUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhoto != oldWidget.initialPhoto) {
      _currentPhoto = widget.initialPhoto;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!widget.enabled) return;

    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _currentPhoto = bytes;
        });
        widget.onPhotoChanged(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _currentPhoto = null;
    });
    widget.onPhotoChanged(null);
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Photo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use camera to take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.green.shade700,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentPhoto != null) ...[
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete, color: Colors.red.shade700),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Delete the current photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Photo container
        GestureDetector(
          onTap: widget.enabled ? _showPickerOptions : null,
          child: Stack(
            children: [
              // Photo or placeholder
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                  image: _currentPhoto != null
                      ? DecorationImage(
                          image: MemoryImage(_currentPhoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      )
                    : _currentPhoto == null
                    ? Icon(
                        Icons.person,
                        size: widget.size * 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),

              // Edit badge
              if (widget.enabled)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _currentPhoto != null ? Icons.edit : Icons.camera_alt,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Label
        if (widget.enabled) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showPickerOptions,
            child: Text(_currentPhoto != null ? 'Change Photo' : 'Add Photo'),
          ),
        ],
      ],
    );
  }
}

/// Compact photo upload for form fields
class PhotoUploadField extends StatelessWidget {
  final Uint8List? photo;
  final ValueChanged<Uint8List?> onChanged;
  final String label;
  final bool required;

  const PhotoUploadField({
    super.key,
    this.photo,
    required this.onChanged,
    this.label = 'Photo',
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        PhotoUploadWidget(
          initialPhoto: photo,
          onPhotoChanged: onChanged,
          size: 100,
        ),
      ],
    );
  }
}

/// Avatar with edit capability
class EditableAvatar extends StatelessWidget {
  final Uint8List? photo;
  final String? initials;
  final double size;
  final VoidCallback? onEdit;

  const EditableAvatar({
    super.key,
    this.photo,
    this.initials,
    this.size = 80,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: photo != null ? MemoryImage(photo!) : null,
          child: photo == null && initials != null
              ? Text(
                  initials!,
                  style: TextStyle(
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                )
              : null,
        ),
        if (onEdit != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  size: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
