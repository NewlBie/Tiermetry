// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final files = [
    r'lib\core\widgets\bottom_nav.dart',
    r'lib\core\widgets\custom_progress_bar.dart',
    r'lib\core\widgets\drawer.dart',
    r'lib\core\widgets\top_bar.dart',
    r'lib\features\arena\presentation\screens\all_arenas_screen.dart',
    r'lib\features\arena\presentation\screens\arena_details_screen.dart',
    r'lib\features\arena\presentation\screens\arena_map_screen.dart',
    r'lib\features\arena\presentation\screens\arena_screen.dart',
    r'lib\features\arena\presentation\widgets\arena_card.dart',
    r'lib\features\arena\presentation\widgets\booking_sheet.dart',
    r'lib\features\arena\presentation\widgets\filter_sheet.dart',
    r'lib\features\home\presentation\widgets\metrics_section.dart',
  ];

  final importStatement = "import 'package:tiermetry/core/theme/colors.dart';";

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;

    var content = file.readAsStringSync();
    if (!content.contains(importStatement)) {
      // Find the last import statment and insert after it
      final lines = content.split('\n');
      int lastImportIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ')) {
          lastImportIndex = i;
        }
      }

      if (lastImportIndex != -1) {
        lines.insert(lastImportIndex + 1, importStatement);
        file.writeAsStringSync(lines.join('\n'));
      } else {
        file.writeAsStringSync('$importStatement\n$content');
      }
      print('Added import to $path');
    }
  }
}
