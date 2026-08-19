import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen>
    with RefreshRateMixin {
  final _profileCtrl = locator.profileCtrl;
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;

  bool _saving = false;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    final p = _profileCtrl.profile;
    _nameController = TextEditingController(text: p?.name ?? '');
    _locationController = TextEditingController(text: p?.location ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _profileCtrl.updateProfile(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        image: _profileImage?.path,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TiermetryTypography.bodySmall(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          enabled: enabled,
          style: TiermetryTypography.bodySmall(
            color: enabled ? Colors.white : Colors.white38,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: TiermetryColors.surfaceElement,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfileImage() {
    final p = _profileCtrl.profile;
    ImageProvider? imageProvider;
    if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    } else if (p?.image != null && p!.image!.isNotEmpty) {
      if (p.image!.startsWith('http')) {
        imageProvider = NetworkImage(p.image!);
      } else {
        imageProvider = AssetImage(p.image!);
      }
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: TiermetryColors.surfaceElement,
              backgroundImage: imageProvider,
              child:
                  imageProvider == null
                      ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white24,
                      )
                      : null,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(('Account & Privacy').toUpperCase(),
          style: TiermetryTypography.title(fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: _saving ? null : _saveChanges,
                child:
                    _saving
                        ? const CupertinoActivityIndicator()
                        : Text(
                          'Save',
                          style: TiermetryTypography.action(
                            color: TiermetryColors.accentNeonGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              const SizedBox(height: 30),
              _buildInputField('Name', _nameController),
              _buildInputField('Location', _locationController),
              _buildInputField(
                'Age',
                _ageController,
                type: TextInputType.number,
              ),
              _buildInputField(
                'Email (Read-only)',
                _emailController,
                enabled: false,
              ),
              const SizedBox(height: 10),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              Text(('Privacy').toUpperCase(),
                style: TiermetryTypography.title(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your account is private by design. No public profile setting is required.',
                style: TiermetryTypography.bodySmall(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
