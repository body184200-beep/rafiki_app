// ignore_for_file: avoid_print

import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('No coverage/lcov.info found!');
    return;
  }

  final lines = file.readAsLinesSync();
  String? currentFile;
  int fileLF = 0;
  int fileLH = 0;

  final Map<String, List<int>> dirStats = {}; // path -> [LH, LF]
  int totalLF = 0;
  int totalLH = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).replaceAll('\\', '/');
      fileLF = 0;
      fileLH = 0;
    } else if (line.startsWith('LF:')) {
      fileLF = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      fileLH = int.parse(line.substring(3));
    } else if (line == 'end_of_record') {
      if (currentFile != null) {
        totalLF += fileLF;
        totalLH += fileLH;

        // Group by direct folder name under lib
        final parts = currentFile.split('/');
        final String category;
        if (parts.length > 2) {
          category = parts.sublist(0, parts.length - 1).join('/');
        } else {
          category = parts[0];
        }

        final stats = dirStats.putIfAbsent(category, () => [0, 0]);
        stats[0] += fileLH;
        stats[1] += fileLF;
      }
    }
  }

  print('===================================================');
  print('               TEST COVERAGE REPORT                ');
  print('===================================================');
  dirStats.forEach((dir, stats) {
    final lh = stats[0];
    final lf = stats[1];
    final pct = lf == 0 ? 0.0 : (lh / lf) * 100;
    print('${dir.padRight(35)}: ${pct.toStringAsFixed(2)}% ($lh/$lf lines)');
  });
  print('---------------------------------------------------');
  final totalPct = totalLF == 0 ? 0.0 : (totalLH / totalLF) * 100;
  print('TOTAL OVERALL COVERAGE            : ${totalPct.toStringAsFixed(2)}% ($totalLH/$totalLF lines)');
  print('===================================================');
}
