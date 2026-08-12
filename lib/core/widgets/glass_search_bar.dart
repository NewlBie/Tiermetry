import 'dart:ui';
import 'package:flutter/material.dart';

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const GlassSearchBar({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.white54),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: Colors.greenAccent,
                    decoration: const InputDecoration(
                      hintText: 'Search arenas, activities...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

