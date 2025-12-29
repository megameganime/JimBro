import 'dart:convert';
import 'package:jim_bro/models/workout_models.dart';
import 'package:jim_bro/widgets/weight_chart.dart' show WeightEntry;
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  // Save weight goal as double
  static Future<void> saveWeightGoal(double weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weightGoal', weight);
  }

  // Get weight goal as double
  static Future<double> getWeightGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble('weightGoal');
    if (value == null) {
      throw Exception('No weight goal found in SharedPreferences');
    }
    return value;
  }

  /// Upsert a single dated weight entry (replace same calendar date or append).
  /// This merges with whatever is already in prefs and avoids overwriting old data.
  static Future<void> upsertDatedWeight(WeightEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('datedWeights') ?? [];

    final newLine = '${entry.date.toIso8601String()},${entry.weight}';

    final idx = list.indexWhere((s) {
      final parts = s.split(',');
      if (parts.isEmpty) return false;
      try {
        final d = DateTime.parse(parts[0]);
        return d.year == entry.date.year &&
            d.month == entry.date.month &&
            d.day == entry.date.day;
      } catch (_) {
        return false;
      }
    });

    if (idx != -1) {
      list[idx] = newLine;
    } else {
      list.add(newLine);
    }

    await prefs.setStringList('datedWeights', list);
  }

  static Future<List<WeightEntry>> getWeeklyWeight() async {
    final prefs = await SharedPreferences.getInstance();
    final weightList = prefs.getStringList('datedWeights');
    if (weightList == null || weightList.isEmpty) {
      throw Exception('No daily weight data found in SharedPreferences');
    }
    // return only the last 7 entries
    final start = weightList.length >= 7 ? weightList.length - 7 : 0;
    final recentWeights = weightList.sublist(start);
    return recentWeights.map((e) {
      final parts = e.split(',');
      return WeightEntry(
        DateTime.parse(parts[0]),
        double.parse(parts[1]),
      );
    }).toList();
  }

  // Unit prefs (store internal data as kilograms; display/entry may be lbs)
  static const String _useLbsKey = 'useLbs';

  /// Save whether user prefers lbs (true) or kg (false)
  static Future<void> setUseLbs(bool useLbs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useLbsKey, useLbs);
  }

  /// Read user's preference. Defaults to false (kg).
  static Future<bool> getUseLbs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useLbsKey) ?? false;
  }

  /// Convert kg -> lbs
  static double kgToLbs(double kg) => kg * 2.2046226218;

  /// Convert lbs -> kg
  static double lbsToKg(double lbs) => lbs / 2.2046226218;

  /// Format a weight (internal kg) according to preference.
  static String formatWeight(double kg, {required bool useLbs, int decimals = 1}) {
    if (useLbs) {
      final value = kgToLbs(kg);
      return '${value.toStringAsFixed(decimals)} lb';
    } else {
      return '${kg.toStringAsFixed(decimals)} kg';
    }
  }

  // ----- Workout templates and instances -----
  static const String _workoutTemplatesKey = 'workoutTemplates';

  /// Save a workout template (only names of exercises are stored per requirements).
  static Future<void> saveWorkoutTemplate(WorkoutTemplate template) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_workoutTemplatesKey) ?? [];
    final idx = list.indexWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['id'] == template.id;
      } catch (_) {
        return false;
      }
    });
    final encoded = jsonEncode(template.toJson());
    if (idx != -1) {
      list[idx] = encoded;
    } else {
      list.add(encoded);
    }
    await prefs.setStringList(_workoutTemplatesKey, list);
  }

  static Future<List<WorkoutTemplate>> getWorkoutTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_workoutTemplatesKey) ?? [];
    return list.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      return WorkoutTemplate.fromJson(m);
    }).toList();
  }

  static Future<void> deleteWorkoutTemplate(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_workoutTemplatesKey) ?? [];
    list.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_workoutTemplatesKey, list);
  }

  /// Instances are stored per-date under key 'workoutInstances_YYYY-MM-DD'
  static String _instancesKeyForDate(DateTime date) =>
      'workoutInstances_${date.toIso8601String().substring(0, 10)}';

  /// Save a workout instance. Input weights should be in user's preferred unit;
  /// this method converts them to kg for internal storage.
  static Future<void> saveWorkoutInstance(WorkoutInstance instance) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _instancesKeyForDate(instance.date);
    final list = prefs.getStringList(key) ?? [];

    // ensure internal storage uses kg
    final useLbs = await getUseLbs();
    final converted = instance.toJson();
    // convert every set weight if useLbs true (weights were provided in lbs)
    if (useLbs) {
      final exercises = converted['exercises'] as List<dynamic>;
      for (final ex in exercises) {
        final sets = ex['sets'] as List<dynamic>;
        for (final s in sets) {
          final weight = (s['weightKg'] as num).toDouble();
          // caller provided weights in lbs -> convert to kg
          s['weightKg'] = lbsToKg(weight);
        }
      }
    }
    final encoded = jsonEncode(converted);

    final idx = list.indexWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['id'] == instance.id;
      } catch (_) {
        return false;
      }
    });
    if (idx != -1) {
      list[idx] = encoded;
    } else {
      list.add(encoded);
    }
    await prefs.setStringList(key, list);
  }

  static Future<List<WorkoutInstance>> getWorkoutInstancesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _instancesKeyForDate(date);
    final list = prefs.getStringList(key) ?? [];
    final useLbs = await getUseLbs();
    final results = list.map((s) {
      final m = jsonDecode(s) as Map<String, dynamic>;
      final inst = WorkoutInstance.fromJson(m);
      // convert internal kg -> lbs for display if needed
      if (useLbs) {
        final convExercises = inst.exercises.map((ex) {
          final convSets = ex.sets.map((set) {
            return SetEntry(
              weightKg: kgToLbs(set.weightKg), // temporarily store displayed weight in weightKg field
              reps: set.reps,
              durationSeconds: set.durationSeconds,
            );
          }).toList();
          return Exercise(id: ex.id, name: ex.name, sets: convSets);
        }).toList();
        return WorkoutInstance(id: inst.id, templateId: inst.templateId, date: inst.date, exercises: convExercises);
      }
      return inst;
    }).toList();
    return results;
  }

  static Future<void> deleteWorkoutInstance(String id, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _instancesKeyForDate(date);
    final list = prefs.getStringList(key) ?? [];
    list.removeWhere((s) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        return m['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(key, list);
  }
}
