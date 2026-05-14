import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tiermetry/core/theme/colors.dart';

class BookingSheet extends StatefulWidget {
  final List<String> selectedDevices;
  final Color accentColor;
  final void Function({
    required int duration,
    required TimeOfDay startTime,
    required int players,
    required List<String> addOns,
  }) onConfirm;

  const BookingSheet({
    super.key,
    required this.selectedDevices,
    required this.accentColor,
    required this.onConfirm,
  });

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  int _duration = 1;
  TimeOfDay _startTime = TimeOfDay.now();
  int _players = 1;
  final Set<String> _addOns = {};
  bool _isProcessing = false;
  int _selectedDateIndex = 0; // 0: Today, 1: Tomorrow

  final List<String> _dates = ["Today", "Tomorrow", "Next Day"];

  double get baseRate => 120;
  double get totalCost => (baseRate * widget.selectedDevices.length * _duration) + (_addOns.length * 30 * _duration);

  void _pickStartTime() async {
    final picked = await showTimePicker(
      context: context, 
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.accentColor,
              onPrimary: Colors.white,
              surface: TiermetryColors.surfaceUnderlay,
            ),
          ),
          child: child!,
        );
      }
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final endTime = TimeOfDay(hour: (_startTime.hour + _duration) % 24, minute: _startTime.minute);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: TiermetryColors.background.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("SELECTED RIGS"),
                    _buildRigSelection(),
                    const SizedBox(height: 28),
                    
                    _buildSectionHeader("DATE & TIME SLOT"),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildTimeAndDurationPicker(context, endTime),
                    const SizedBox(height: 32),

                    _buildSectionHeader("PLAYERS"),
                    _buildPlayerCounter(),
                    const SizedBox(height: 32),

                    _buildSectionHeader("PREMIUM ADD-ONS"),
                    _buildAddonsGrid(),
                    const SizedBox(height: 100), // Space for footer
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ).animate().moveY(begin: 300, end: 0, duration: 400.ms, curve: Curves.easeOutCirc),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0).copyWith(top: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Reservation", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            style: IconButton.styleFrom(backgroundColor: Colors.white10),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: GoogleFonts.inter(color: widget.accentColor, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }

  Widget _buildRigSelection() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.selectedDevices.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.computer_rounded, size: 18, color: Colors.white60),
                const SizedBox(width: 10),
                Text(widget.selectedDevices[index], style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: List.generate(_dates.length, (index) {
        bool isSelected = _selectedDateIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: Container(
              margin: EdgeInsets.only(right: index == _dates.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? widget.accentColor.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? widget.accentColor : Colors.white10),
              ),
              child: Center(
                child: Text(
                  _dates[index],
                  style: GoogleFonts.inter(color: isSelected ? Colors.white : Colors.white60, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimeAndDurationPicker(BuildContext context, TimeOfDay endTime) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _pickStartTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: TiermetryColors.surfaceUnderlay, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("START AT", style: GoogleFonts.inter(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_startTime.format(context), style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: TiermetryColors.surfaceUnderlay, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("DURATION", style: GoogleFonts.inter(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                CupertinoSlidingSegmentedControl<int>(
                  groupValue: _duration,
                  onValueChanged: (val) => setState(() => _duration = val ?? 1),
                  thumbColor: widget.accentColor,
                  backgroundColor: Colors.black26,
                  children: { for(var i = 1; i <= 4; i++) i: Text("${i}h", style: GoogleFonts.inter(color: Colors.white, fontSize: 13)) },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCounter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: TiermetryColors.surfaceUnderlay, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, color: Colors.white54),
          const SizedBox(width: 16),
          Text("Total Players", style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          const Spacer(),
          _counterButton(Icons.remove_rounded, () => setState(() => _players = (_players - 1).clamp(1, 8))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("$_players", style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          _counterButton(Icons.add_rounded, () => setState(() => _players = (_players + 1).clamp(1, 8))),
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildAddonsGrid() {
    final List<Map<String, dynamic>> addons = [
      {'label': '🎧 Headset', 'price': '₹30'},
      {'label': '🎮 Controller', 'price': '₹40'},
      {'label': '⚡ FPS Boost', 'price': '₹20'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: addons.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1),
      itemBuilder: (context, index) {
        final addon = addons[index];
        final isSelected = _addOns.contains(addon['label']);
        return GestureDetector(
          onTap: () => setState(() => isSelected ? _addOns.remove(addon['label']) : _addOns.add(addon['label'])),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? widget.accentColor.withValues(alpha: 0.15) : TiermetryColors.surfaceUnderlay,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? widget.accentColor : Colors.white10, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(addon['label'].split(' ')[0], style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 8),
                Text(addon['label'].split(' ')[1], style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                Text(addon['price'], style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: Colors.black45,
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TOTAL PRICE", style: GoogleFonts.inter(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("₹", style: GoogleFonts.inter(fontSize: 16, color: widget.accentColor, fontWeight: FontWeight.bold)),
                          Text("${totalCost.toInt()}", style: GoogleFonts.inter(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 180,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isProcessing ? null : () async {
                        setState(() => _isProcessing = true);
                        await Future.delayed(const Duration(milliseconds: 1800));
                        if (mounted) widget.onConfirm(duration: _duration, startTime: _startTime, players: _players, addOns: _addOns.toList());
                      },
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(16),
                      child: _isProcessing 
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text("Confirm & Pay", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
