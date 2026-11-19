import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Exercise {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? level;
  final String? category;
  final String? equipment;
  final String? force;
  final String? mechanic;
  final List<String> primary;
  final List<String> secondary;
  final List<String> stepsAr;
  final List<String> stepsEn;
  final List<String> images;

  const Exercise({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.level,
    this.category,
    this.equipment,
    this.force,
    this.mechanic,
    required this.primary,
    required this.secondary,
    required this.stepsAr,
    required this.stepsEn,
    required this.images,
  });

  static List<String> _list(dynamic v) =>
      v == null ? const [] : List<String>.from(v as List);

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as String,
        nameAr: j['name_ar'] as String,
        nameEn: j['name_en'] as String,
        level: j['level'] as String?,
        category: j['category'] as String?,
        equipment: j['equipment'] as String?,
        force: j['force'] as String?,
        mechanic: j['mechanic'] as String?,
        primary: _list(j['primary_muscles']),
        secondary: _list(j['secondary_muscles']),
        stepsAr: _list(j['instructions_ar']),
        stepsEn: _list(j['instructions_en']),
        images: _list(j['images']),
      );
}

class ExerciseRepo {
  static List<Exercise>? _cache;

  static Future<List<Exercise>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('data/exercises_ar.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
    return list;
  }
}
