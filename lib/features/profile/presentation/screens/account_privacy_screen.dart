import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiermetry/core/constants/app_avatars.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/mixins/refresh_rate_mixin.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/radii.dart';
import 'package:tiermetry/core/theme/spacing.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/utils/account_input_validator.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/app_surface.dart';
import 'package:tiermetry/core/widgets/india_city_picker_sheet.dart';
import '../widgets/avatar_selection_sheet.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen>
    with RefreshRateMixin {
  final _profileCtrl = locator.profileCtrl;
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;

  bool _saving = false;
  late int _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    final p = _profileCtrl.profile;
    _selectedAvatarId = p?.avatarId ?? AppAvatar.defaultAvatarId;
    _nameController = TextEditingController(text: p?.name ?? '');
    _usernameController = TextEditingController(text: p?.username ?? '');
    _phoneController = TextEditingController(
      text: p?.phoneNumber?.replaceFirst(RegExp(r'^\+91'), '') ?? '',
    );
    _locationController = TextEditingController(text: p?.location ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _chooseAvatar() async {
    final chosenId = await showAvatarSelectionSheet(
      context,
      currentAvatarId: _selectedAvatarId,
    );
    if (chosenId != null && mounted) {
      setState(() => _selectedAvatarId = chosenId);
    }
  }

  void _saveChanges() async {
    final nameError = AccountInputValidator.nameError(_nameController.text);
    final username = _normalizedUsername;
    final usernameError = AccountInputValidator.usernameError(username ?? '');
    final locationError = AccountInputValidator.locationError(
      _locationController.text,
    );
    final phoneError = AccountInputValidator.indiaPhoneError(
      _phoneController.text,
    );
    final ageError = AccountInputValidator.ageError(_ageController.text);
    if (nameError != null ||
        usernameError != null ||
        locationError != null ||
        phoneError != null ||
        ageError != null) {
      AppIslandNotice.show(
        context,
        title: 'Check your details',
        message:
            nameError ??
            usernameError ??
            locationError ??
            phoneError ??
            ageError,
        tone: AppIslandNoticeTone.warning,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final currentUsername = _profileCtrl.profile?.username;
      if (username != currentUsername &&
          !await _profileCtrl.isUsernameAvailable(username!)) {
        throw Exception('That username is already taken.');
      }
      await _profileCtrl.updateProfile(
        name: _nameController.text.trim(),
        username: username,
        phoneNumber: AccountInputValidator.indiaPhoneE164(
          _phoneController.text,
        ),
        location: _locationController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        clearAge: _ageController.text.trim().isEmpty,
        avatarId: _selectedAvatarId,
      );
      if (!mounted) return;
      AppIslandNotice.show(
        context,
        title: 'Profile updated',
        tone: AppIslandNoticeTone.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppIslandNotice.show(
        context,
        title: 'Could not update profile',
        message: e.toString().replaceFirst('Exception: ', ''),
        tone: AppIslandNoticeTone.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? get _normalizedUsername {
    final value = _usernameController.text.trim();
    if (value.isEmpty) return null;
    return AccountInputValidator.normalizeUsername(value);
  }

  String _normalizePhoneInput(String value) {
    var digits = AccountInputValidator.digitsOnly(value);
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits.length > 10 ? digits.substring(0, 10) : digits;
  }

  Future<void> _pickLocation() async {
    final city = await showIndiaCityPicker(
      context,
      selectedCity: _locationController.text,
      searchCities: locator.locationCtrl.searchCities,
    );
    if (city != null && mounted) {
      setState(() => _locationController.text = city);
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    TextInputType? type,
    bool enabled = true,
    VoidCallback? onTap,
    bool isLast = false,
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
          readOnly: onTap != null,
          onTap: onTap,
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
        if (!isLast) const SizedBox(height: TiermetrySpacing.lg),
      ],
    );
  }

  Widget _buildPhoneField({bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone',
          style: TiermetryTypography.bodySmall(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TiermetryTypography.bodySmall(
            color: Colors.white,
            fontSize: 14,
          ),
          onChanged: (value) {
            final digits = _normalizePhoneInput(value);
            if (digits != value) {
              _phoneController.value = TextEditingValue(
                text: digits,
                selection: TextSelection.collapsed(offset: digits.length),
              );
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: TiermetryColors.surfaceElement,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: const Text(
                  '+91',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 70),
            hintText: 'Mobile number',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: TiermetrySpacing.lg),
      ],
    );
  }

  Widget _section({
    required String eyebrow,
    required String title,
    required Widget child,
  }) => AppSurface(
    padding: const EdgeInsets.all(TiermetrySpacing.lg),
    color: TiermetryColors.surfaceUnderlay,
    borderRadius: TiermetryRadii.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TiermetryTypography.label(color: TiermetryColors.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: TiermetryTypography.bodySmall(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TiermetrySpacing.lg),
        child,
      ],
    ),
  );

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _chooseAvatar,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: TiermetryColors.surfaceElement,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white12),
                image: DecorationImage(
                  image: AssetImage(AppAvatar.assetForId(_selectedAvatarId)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TiermetryColors.accentNeonGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.edit, size: 14, color: Colors.black),
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
        title: Text(
          'Personal information',
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
                          'SAVE',
                          style: TiermetryTypography.action(
                            color: TiermetryColors.accentNeonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TiermetrySpacing.screenPadding,
            TiermetrySpacing.md,
            TiermetrySpacing.screenPadding,
            TiermetrySpacing.bottomSafeArea,
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSurface(
                  padding: const EdgeInsets.all(TiermetrySpacing.lg),
                  color: TiermetryColors.surfaceUnderlay,
                  borderRadius: TiermetryRadii.lg,
                  child: Row(
                    children: [
                      SizedBox(width: 92, child: _buildProfileImage()),
                      const SizedBox(width: TiermetrySpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR IDENTITY',
                              style: TiermetryTypography.label(
                                color: TiermetryColors.accentNeonGreen,
                              ),
                            ),
                            const SizedBox(height: TiermetrySpacing.xs),
                            Text(
                              'Keep it recognisably you',
                              style: TiermetryTypography.title(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Tap your photo to update it.',
                              style: TiermetryTypography.bodySmall(
                                color: TiermetryColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.md),
                _section(
                  eyebrow: 'THE BASICS',
                  title: 'How friends see you',
                  child: Column(
                    children: [
                      _buildInputField('Name', _nameController),
                      _buildInputField('Username', _usernameController),
                      _buildPhoneField(),
                      _buildInputField(
                        'Age',
                        _ageController,
                        type: TextInputType.number,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.md),
                _section(
                  eyebrow: 'YOUR PLACE',
                  title: 'Where you play',
                  child: _buildInputField(
                    'City',
                    _locationController,
                    onTap: _pickLocation,
                    isLast: true,
                  ),
                ),
                const SizedBox(height: TiermetrySpacing.md),
                _section(
                  eyebrow: 'SIGN-IN',
                  title: 'Your account email',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        'Email',
                        _emailController,
                        enabled: false,
                        isLast: true,
                      ),
                      const SizedBox(height: TiermetrySpacing.sm),
                      Text(
                        'Change this securely from Account settings.',
                        style: TiermetryTypography.bodySmall(
                          color: TiermetryColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
