import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tiermetry/core/locator.dart';
import 'package:tiermetry/core/theme/colors.dart';
import 'package:tiermetry/root.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // Form fields
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _dobController = TextEditingController();
  String _selectedAvatar = 'assets/User.png';
  
  final List<String> _platforms = [];
  final List<String> _interests = [];
  final List<String> _games = [];

  final List<String> _availablePlatforms = ['PC', 'PlayStation', 'Xbox', 'Mobile', 'Tabletop'];
  final List<String> _availableInterests = ['Esports', 'Casual', 'RPG', 'FPS', 'Strategy', 'Racing', 'Simulation'];
  final List<String> _availableGames = ['Valorant', 'CS2', 'FIFA', 'D&D', 'Apex Legends', 'League of Legends'];
  final List<String> _availableAvatars = ['assets/User.png', 'assets/Seller.png']; // Mock avatars

  @override
  void initState() {
    super.initState();
    // Pre-fill name if available from auth
    final user = locator.authCtrl.user;
    if (user?.name != null) {
      _nameController.text = user!.name!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishSetup();
    }
  }

  Future<void> _finishSetup() async {
    setState(() => _isLoading = true);
    
    // In a real app, this would call locator.profileCtrl.updateProfile(ProfileEntity(...))
    // We will just simulate a network delay
    await Future<void>.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (context) => const Root()),
      );
    }
  }

  Widget _buildStep1Basics() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Basic Info',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let players know who you are.',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('Full Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('Username (e.g. @gamer)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dobController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDeco('City / Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Avatar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose an Avatar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _availableAvatars.map((asset) {
              final isSelected = _selectedAvatar == asset;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = asset),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? TiermetryColors.primary : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage(asset),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
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

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> items1,
    required List<String> selectedItems1,
    List<String>? items2,
    List<String>? selectedItems2,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
            children: items1.map((item) {
              final isSelected = selectedItems1.contains(item);
              return ChoiceChip(
                label: Text(item),
                selected: isSelected,
                selectedColor: TiermetryColors.primary,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              children: items2.map((item) {
                final isSelected = selectedItems2.contains(item);
                return ChoiceChip(
                  label: Text(item),
                  selected: isSelected,
                  selectedColor: TiermetryColors.primary,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          ]
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
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
                physics: const NeverScrollableScrollPhysics(), // Force using buttons
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
              padding: const EdgeInsets.all(24.0),
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
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TiermetryColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
