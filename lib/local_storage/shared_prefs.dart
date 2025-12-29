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

  // Save daily weight entries as list of strings
  static Future<void> datedWeights(List<WeightEntry> weight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'datedWeights',
      weight.map((e) => '${e.date.toIso8601String()},${e.weight}').toList(),
    );
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
}
