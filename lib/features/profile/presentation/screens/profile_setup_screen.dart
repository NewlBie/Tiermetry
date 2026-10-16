import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/constants/app_avatars.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/core/theme/typography.dart';
import 'package:tiermetry/core/utils/account_input_validator.dart';
import 'package:tiermetry/core/widgets/app_island_notice.dart';
import 'package:tiermetry/core/widgets/india_city_picker_sheet.dart';
import 'package:tiermetry/root.dart';
import '../widgets/avatar_carousel_picker.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isCheckingUsername = false;
  String? _usernameFeedback;

  // Form fields
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  int _selectedAvatarId = AppAvatar.defaultAvatarId;

  final List<String> _platforms = [];
  final List<String> _interests = [];
  final List<String> _games = [];

  final List<String> _availablePlatforms = [
    'PC',
    'PlayStation',
    'Xbox',
    'Mobile',
    'Tabletop',
  ];
  final List<String> _availableInterests = [
    'Esports',
    'Casual',
    'RPG',
    'FPS',
    'Strategy',
    'Racing',
    'Simulation',
  ];
  final List<String> _availableGames = [
    'Valorant',
    'CS2',
    'FIFA',
    'D&D',
    'Apex Legends',
    'League of Legends',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available from auth
    final user = locator.authCtrl.user;
    if (user?.name != null) {
      _nameController.text = user!.name!;
    }
    final profile = locator.profileCtrl.profile;
    if (profile != null) {
      _selectedAvatarId = profile.avatarId;
      if (profile.name.trim().isNotEmpty) {
        _nameController.text = profile.name;
      }
      _usernameController.text = profile.username ?? '';
      _phoneController.text =
          profile.phoneNumber?.replaceFirst(RegExp(r'^\+91'), '') ?? '';
      _locationController.text = profile.location;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0 && !await _validateIdentityStep()) return;

    if (_currentPage < 3) {
      unawaited(
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    } else {
      await _finishSetup();
    }
  }

  Future<bool> _validateIdentityStep() async {
    final nameError = AccountInputValidator.nameError(_nameController.text);
    final locationError = AccountInputValidator.locationError(
      _locationController.text,
    );
    final usernameError = AccountInputValidator.usernameError(
      _usernameController.text,
    );
    final phoneError = AccountInputValidator.indiaPhoneError(
      _phoneController.text,
    );

    if (nameError != null ||
        locationError != null ||
        usernameError != null ||
        phoneError != null) {
      setState(() => _usernameFeedback = usernameError);
      AppIslandNotice.show(
        context,
        title: 'Check your details',
        message: nameError ?? locationError ?? usernameError ?? phoneError!,
        tone: AppIslandNoticeTone.warning,
      );
      return false;
    }

    final username = AccountInputValidator.normalizeUsername(
      _usernameController.text,
    );
    _usernameController.text = username;
    setState(() {
      _isCheckingUsername = true;
      _usernameFeedback = null;
    });

    try {
      final isAvailable = await locator.profileCtrl.isUsernameAvailable(
        username,
      );
      if (!mounted) return false;
      if (!isAvailable) {
        setState(() => _usernameFeedback = '@$username is already taken.');
        return false;
      }
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _usernameFeedback = 'Could not check this username. Try again.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isCheckingUsername = false);
    }
  }

  Future<void> _finishSetup() async {
    setState(() => _isLoading = true);

    try {
      await locator.profileCtrl.updateProfile(
        name: _nameController.text.trim(),
        username: _normalizedUsername,
        phoneNumber: AccountInputValidator.indiaPhoneE164(
          _phoneController.text,
        ),
        location: _locationController.text.trim(),
        avatarId: _selectedAvatarId,
        image: AppAvatar.assetForId(_selectedAvatarId),
        platforms: List.unmodifiable(_platforms),
        interests: List.unmodifiable(_interests),
        preferredGames: List.unmodifiable(_games),
        profileSetupCompleted: true,
      );

      // The launch gate reads this value after every app start, so verify the
      // database state before leaving onboarding.
      await locator.profileCtrl.loadProfile();
      if (locator.profileCtrl.profile?.profileSetupCompleted != true) {
        throw Exception('Profile setup was not confirmed. Please try again.');
      }

      locator.locationCtrl.selectCity(_locationController.text.trim());
      if (!mounted) return;
      await Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (context) => const Root()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppIslandNotice.show(
        context,
        title: 'Profile not saved',
        message: e.toString().replaceFirst('Exception: ', ''),
        tone: AppIslandNoticeTone.error,
      );
      setState(() => _isLoading = false);
    }
  }

  String? get _normalizedUsername {
    final value = AccountInputValidator.normalizeUsername(
      _usernameController.text,
    );
    return value.isEmpty ? null : value;
  }

  String _normalizePhoneInput(String value) {
    var digits = AccountInputValidator.digitsOnly(value);
    if (digits.length > 10 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }
    return digits.length > 10 ? digits.substring(0, 10) : digits;
  }

  Future<void> _chooseCity() async {
    final city = await showIndiaCityPicker(
      context,
      searchCities: locator.locationCtrl.searchCities,
      selectedCity: _locationController.text.trim(),
    );
    if (city != null && mounted) {
      setState(() => _locationController.text = city);
    }
  }

  Widget _buildStep1Basics() {
    return _buildStepShell(
      children: [
        Row(
          children: [
            _stepBadge('1 of 4'),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.25,
                  child: Container(
                    decoration: BoxDecoration(
                      color: TiermetryColors.accentNeonGreen,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: TiermetryColors.accentNeonGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: TiermetryColors.accentNeonGreen.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.waving_hand_rounded,
            color: Colors.black,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tell us about you',
          style: GoogleFonts.geist(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'This helps friends recognise you and keeps bookings reachable.',
          style: GoogleFonts.geist(
            color: Colors.white.withValues(alpha: 0.62),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 30),
        _ProfileSetupField(
          controller: _nameController,
          label: 'Full name',
          hint: 'Neal Biju',
          icon: Icons.badge_rounded,
        ),
        const SizedBox(height: 14),
        _ProfileSetupField(
          controller: _usernameController,
          label: 'Username',
          hint: 'newbie1',
          icon: Icons.alternate_email_rounded,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) {
            if (_usernameFeedback != null) {
              setState(() => _usernameFeedback = null);
            }
          },
          prefixText: '@',
          helperText:
              _usernameFeedback ??
              '3-20 lowercase letters, numbers, or underscores.',
          helperColor:
              _usernameFeedback == null
                  ? Colors.white.withValues(alpha: 0.44)
                  : TiermetryColors.negative,
          isError: _usernameFeedback != null,
        ),
        const SizedBox(height: 14),
        _ProfileSetupPhoneField(
          controller: _phoneController,
          onNormalize: _normalizePhoneInput,
        ),
        const SizedBox(height: 14),
        _ProfileSetupField(
          controller: _locationController,
          label: 'City',
          hint: 'Choose your city',
          icon: Icons.location_on_rounded,
          readOnly: true,
          onTap: _chooseCity,
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white.withValues(alpha: 0.64),
          ),
        ),
      ],
    );
  }

  Widget _buildStepShell({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2Avatar() {
    return _buildStepShell(
      children: [
        Text(
          'Choose an Avatar',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Swipe to select your player avatar',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: TiermetryColors.textMuted,
          ),
        ),
        const SizedBox(height: 36),
        AvatarCarouselPicker(
          selectedAvatarId: _selectedAvatarId,
          height: 200,
          itemDiameter: 140,
          onAvatarChanged: (id) {
            setState(() => _selectedAvatarId = id);
          },
        ),
      ],
    );
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> items1,
    required List<String> selectedItems1,
    List<String>? items2,
    List<String>? selectedItems2,
  }) {
    return _buildStepShell(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children:
              items1.map((item) {
                final isSelected = selectedItems1.contains(item);
                return ChoiceChip(
                  label: Text(item),
                  selected: isSelected,
                  selectedColor: TiermetryColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        selectedItems1.add(item);
                      } else {
                        selectedItems1.remove(item);
                      }
                    });
                  },
                );
              }).toList(),
        ),
        if (items2 != null && selectedItems2 != null) ...[
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children:
                items2.map((item) {
                  final isSelected = selectedItems2.contains(item);
                  return ChoiceChip(
                    label: Text(item),
                    selected: isSelected,
                    selectedColor: TiermetryColors.primary,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          selectedItems2.add(item);
                        } else {
                          selectedItems2.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3Interests() {
    return _buildSelectionStep(
      title: 'Platforms & Interests',
      subtitle: 'What and where do you play?',
      items1: _availablePlatforms,
      selectedItems1: _platforms,
      items2: _availableInterests,
      selectedItems2: _interests,
    );
  }

  Widget _buildStep4Games() {
    return _buildSelectionStep(
      title: 'Favorite Games',
      subtitle: 'Select top games you play.',
      items1: _availableGames,
      selectedItems1: _games,
    );
  }

  Widget _stepBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TiermetryTypography.caption(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Force using buttons
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStep1Basics(),
                  _buildStep2Avatar(),
                  _buildStep3Interests(),
                  _buildStep4Games(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _nextPage,
                      child: Text(
                        'Skip for now',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed:
                        _isLoading || _isCheckingUsername ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isLoading || _isCheckingUsername
                              ? Colors.white.withValues(alpha: 0.14)
                              : TiermetryColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child:
                        _isLoading || _isCheckingUsername
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              _currentPage == 3 ? 'Finish' : 'Next',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSetupField extends StatelessWidget {
  const _ProfileSetupField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.onTap,
    this.onChanged,
    this.prefixText,
    this.suffixIcon,
    this.helperText,
    this.helperColor,
    this.isError = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final bool autocorrect;
  final bool enableSuggestions;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final Widget? suffixIcon;
  final String? helperText;
  final Color? helperColor;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isError
            ? TiermetryColors.negative.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.07);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            autocorrect: autocorrect,
            enableSuggestions: enableSuggestions,
            onTap: onTap,
            onChanged: onChanged,
            style: GoogleFonts.geist(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: GoogleFonts.geist(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              hintText: hint,
              hintStyle: GoogleFonts.geist(
                color: Colors.white.withValues(alpha: 0.28),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.58),
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 54),
              prefixText: prefixText,
              prefixStyle: GoogleFonts.geist(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(0, 16, 18, 16),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              helperText!,
              style: GoogleFonts.geist(
                color: helperColor ?? Colors.white.withValues(alpha: 0.46),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileSetupPhoneField extends StatelessWidget {
  const _ProfileSetupPhoneField({
    required this.controller,
    required this.onNormalize,
  });

  final TextEditingController controller;
  final String Function(String value) onNormalize;

  @override
  Widget build(BuildContext context) {
    return _ProfileSetupField(
      controller: controller,
      label: 'Phone',
      hint: '9021552082',
      icon: Icons.phone_iphone_rounded,
      keyboardType: TextInputType.phone,
      onChanged: (value) {
        final digits = onNormalize(value);
        if (digits != value) {
          controller.value = TextEditingValue(
            text: digits,
            selection: TextSelection.collapsed(offset: digits.length),
          );
        }
      },
      helperText: 'Only Indian numbers are supported for now.',
      helperColor: Colors.white.withValues(alpha: 0.44),
      prefixText: '+91 ',
    );
  }
}
