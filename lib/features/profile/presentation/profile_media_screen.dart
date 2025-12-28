import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/supabase_client.dart';

class ProfileMediaScreen extends ConsumerStatefulWidget {
  const ProfileMediaScreen({super.key});

  @override
  ConsumerState<ProfileMediaScreen> createState() => _ProfileMediaScreenState();
}

class _ProfileMediaScreenState extends ConsumerState<ProfileMediaScreen> {
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _uploadedUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await pickedFile.readAsBytes();
      }
      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
        _uploadedUrl = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    setState(() => _isUploading = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final fileExt = _imageFile!.name.split('.').last;
      final fileName =
          'profile_$userId.${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      String? storageResponse;
      if (kIsWeb) {
        // On web, upload bytes
        storageResponse = await supabase.storage
            .from('profiles')
            .uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        // On mobile, upload file
        storageResponse = await supabase.storage
            .from('profiles')
            .upload(
              fileName,
              File(_imageFile!.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }
      if (storageResponse == null || storageResponse.isEmpty) {
        throw Exception('Upload failed');
      }

      // Get public URL
      final publicUrl = supabase.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Update profile photo URL in database
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getMyProfile();
      if (profile == null) throw Exception('Profile not found');
      await profileRepo.upsertMyProfile(
        profile.copyWith(profilePhotoUrl: publicUrl),
      );

      setState(() {
        _uploadedUrl = publicUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile Photo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[300],
              backgroundImage: _uploadedUrl != null
                  ? NetworkImage(_uploadedUrl!)
                  : _imageBytes != null
                  ? MemoryImage(_imageBytes!)
                  : null,
              child: _uploadedUrl == null && _imageBytes == null
                  ? const Icon(Icons.person, size: 70, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Choose from Gallery'),
              onPressed: _isUploading ? null : _pickImage,
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              ElevatedButton.icon(
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isUploading ? 'Uploading...' : 'Save'),
                onPressed: _isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
