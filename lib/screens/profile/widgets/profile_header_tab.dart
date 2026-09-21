import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
// import 'package:get/get.dart';
import 'package:interprep/common/constants/styles.dart';
import 'package:interprep/common/resources/widgets/buttons/app_text_button.dart';
import 'package:interprep/common/resources/widgets/textfields/app_text_field.dart';
import 'package:interprep/common/resources/widgets/toast/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProfileHeaderTab extends StatefulWidget {
  final String userName;
  final String userEmail;
  final Function(String) onNameUpdated;

  const ProfileHeaderTab({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onNameUpdated,
  });

  @override
  State<ProfileHeaderTab> createState() => _ProfileHeaderTabState();
}

class _ProfileHeaderTabState extends State<ProfileHeaderTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userName;
    _loadProfilePhoto();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['photoUrl'] != null) {
          setState(() {
            _profilePhotoUrl = userDoc.data()!['photoUrl'] as String;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _nameController.text.trim(),
        });

        widget.onNameUpdated(_nameController.text.trim());
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });

        CustomToast.showSuccess('Profile updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      CustomToast.showError('Failed to update profile');
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        _nameController.text = widget.userName;
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _isUploadingPhoto = true;
        });

        final user = _auth.currentUser;
        if (user == null) return;

        // Upload to Firebase Storage
        final String fileName = 'profile_photos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = _storage.ref().child(fileName);
        
        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          uploadTask = ref.putData(bytes);
        } else {
          uploadTask = ref.putFile(File(image.path));
        }

        // Wait for upload to complete
        await uploadTask.whenComplete(() => {});
        
        // Get download URL
        final String downloadUrl = await ref.getDownloadURL();

        // Update Firestore with photo URL
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        setState(() {
          _profilePhotoUrl = downloadUrl;
          _isUploadingPhoto = false;
        });

        CustomToast.showSuccess('Profile photo updated successfully');
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      CustomToast.showError('Failed to upload photo');
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Profile Icon/Avatar
            Center(
              child: Stack(
                children: [
                  _isUploadingPhoto
                      ? const CircleAvatar(
                          radius: 60,
                          child: CircularProgressIndicator(),
                        )
                      : CircleAvatar(
                          radius: 60,
                          backgroundColor: Styles.primaryColor.withValues(alpha: 0.2),
                          backgroundImage: _profilePhotoUrl != null
                              ? NetworkImage(_profilePhotoUrl!)
                              : null,
                          child: _profilePhotoUrl == null
                              ? Text(
                                  widget.userName.isNotEmpty
                                      ? widget.userName[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Styles.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Styles.primaryColor,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        onPressed: _isUploadingPhoto ? null : _pickImage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // ... existing name and email fields code ...
            _isEditing
                ? AppTextField(
                    label: "Name",
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      } else if (!RegExp(r'^[a-z A-Z]+$').hasMatch(value)) {
                        return "Enter a valid name";
                      }
                      return null;
                    },
                  )
                : TextFormField(
                    decoration: InputDecoration(
                      labelText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.only(
                        left: 20,
                        top: 19,
                        bottom: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _toggleEditMode,
                      ),
                    ),
                    controller: _nameController,
                    enabled: false,
                    style: const TextStyle(color: Colors.grey),
                  ),
            const SizedBox(height: 20),
            // Email Field (Read-only)
            TextFormField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              initialValue: widget.userEmail,
              enabled: false,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Save Button (only shown when editing)
            if (_isEditing)
              AppTextButton(
                text: _isSaving ? "Saving..." : "Save Changes",
                onTap: _isSaving ? () {} : _updateProfile,
                color: Styles.primaryColor,
                disabled: _isSaving,
              ),
            const SizedBox(height: 20),
            // Account Info Card with real-time data
            _buildAccountInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final accountType = userData?['accountType'] ?? 'User';
        final memberSince = _getMemberSince();

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Information',
                  style: Styles.displayLargeBoldStyle,
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person, 'Name', widget.userName),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.email, 'Email', widget.userEmail),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.badge, 'Account Type', accountType.toString()),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, 'Member Since', memberSince),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Styles.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMemberSince() {
    final user = _auth.currentUser;
    if (user?.metadata.creationTime != null) {
      final date = user!.metadata.creationTime!;
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'N/A';
  }
}