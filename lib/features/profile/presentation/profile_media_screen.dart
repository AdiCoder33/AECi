import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileMediaScreen extends StatefulWidget {
  const ProfileMediaScreen({super.key});

  @override
  State<ProfileMediaScreen> createState() => _ProfileMediaScreenState();
}

class _ProfileMediaScreenState extends State<ProfileMediaScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // TODO: Upload the image to your backend and update the profile photo URL
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
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null
                  ? const Icon(Icons.person, size: 70, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Choose from Gallery'),
              onPressed: _pickImage,
            ),
            // You can add a save button here to upload the image to your backend
          ],
        ),
      ),
    );
  }
}
