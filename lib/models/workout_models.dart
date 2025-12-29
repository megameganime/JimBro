import 'dart:convert';

class WorkoutTemplate {
  final String id;
  final String name;
  final List<String> exerciseNames;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exerciseNames,
  });

  factory WorkoutTemplate.create(String name, [List<String>? exerciseNames]) {
    return WorkoutTemplate(
      // use microseconds to reduce collisions when creating many items quickly
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      exerciseNames: exerciseNames ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exerciseNames': exerciseNames,
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      exerciseNames: List<String>.from(json['exerciseNames'] ?? []),
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

class WorkoutInstance {
  final String id;
  final String? templateId;
  final DateTime date;
  final List<Exercise> exercises;

  WorkoutInstance({
    required this.id,
    this.templateId,
    required this.date,
    required this.exercises,
  });

  factory WorkoutInstance.create({String? templateId, required DateTime date, required List<Exercise> exercises}) {
    return WorkoutInstance(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      templateId: templateId,
      date: date,
      exercises: exercises,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutInstance.fromJson(Map<String, dynamic> json) {
    return WorkoutInstance(
      id: json['id'] as String,
      templateId: json['templateId'] as String?,
      date: DateTime.parse(json['date'] as String),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final List<SetEntry> sets;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
  });

  factory Exercise.create(String name) {
    return Exercise(
      // use microseconds to reduce collisions
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      sets: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map((s) => SetEntry.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
    );
  }
}

class SetEntry {
  // Stored internally as kilograms
  final double weightKg;
  final int reps;
  final int? durationSeconds;

  SetEntry({
    required this.weightKg,
    required this.reps,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'reps': reps,
        'durationSeconds': durationSeconds,
      };

  factory SetEntry.fromJson(Map<String, dynamic> json) {
    return SetEntry(
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      durationSeconds: json['durationSeconds'] as int?,
    );
  }
}