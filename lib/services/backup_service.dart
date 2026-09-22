import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/providers.dart';
import '../data/models.dart';

/// Local-only backup/export — no network involved.
class BackupService {
  static Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final json = repo.exportJsonString();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/fitlog-backup-${dayKey(DateTime.now())}.json',
      );
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], subject: 'FitLog backup');
    } catch (_) {
      // web: download via share of bytes
      await Share.share(json, subject: 'fitlog-backup.json');
    }
  }

  static Future<void> importBackup(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    final f = picked?.files.firstOrNull;
    if (f == null) return;
    final String? text = f.bytes != null
        ? String.fromCharCodes(f.bytes!)
        : (f.path == null ? null : await File(f.path!).readAsString());
    if (text == null) return;
    try {
      await ref.read(repositoryProvider).importJsonString(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Backup imported')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Invalid backup file')));
      }
    }
  }

  static Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(repositoryProvider);
    final byDay = <String, Map<String, double>>{};
    void add(String day, String k, double v) =>
        byDay.putIfAbsent(day, () => {})[k] = (byDay[day]?[k] ?? 0) + v;

    for (final l in repo.allFoodLogs) {
      add(l.date, 'kcal', l.calories);
      add(l.date, 'protein', l.protein);
      add(l.date, 'carbs', l.carbs);
      add(l.date, 'fat', l.fat);
    }
    for (final w in repo.allWorkouts) {
      add(w.date, 'burned', w.estimatedCalories);
      add(w.date, 'workoutMin', w.durationSeconds / 60);
    }
    for (final w in repo.allWater) {
      add(dayKey(w.timestamp), 'waterMl', w.amountMl.toDouble());
    }
    final weightByDay = <String, double>{};
    for (final w in repo.weights) {
      weightByDay[dayKey(w.timestamp)] = w.weightKg;
    }

    final days = {...byDay.keys, ...weightByDay.keys}.toList()..sort();
    final sb = StringBuffer(
      'date,weight,caloriesConsumed,caloriesBurned,protein,carbs,fat,waterMl,workoutMin\n',
    );
    for (final d in days) {
      final m = byDay[d] ?? {};
      sb.writeln(
        [
          d,
          weightByDay[d]?.toStringAsFixed(1) ?? '',
          m['kcal']?.round() ?? 0,
          m['burned']?.round() ?? 0,
          m['protein']?.round() ?? 0,
          m['carbs']?.round() ?? 0,
          m['fat']?.round() ?? 0,
          m['waterMl']?.round() ?? 0,
          m['workoutMin']?.round() ?? 0,
        ].join(','),
      );
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/fitlog-export-${dayKey(DateTime.now())}.csv',
      );
      await file.writeAsString(sb.toString());
      await Share.shareXFiles([XFile(file.path)], subject: 'FitLog CSV');
    } catch (_) {
      await Share.share(sb.toString(), subject: 'fitlog-export.csv');
    }
  }
}
