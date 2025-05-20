// lib/models/medication_model.dart
// Añade esta importación en todos los archivos que usan TimeOfDay
import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final TimeOfDay scheduledTime;
  final List<bool> weekDays; // [lun, mar, mie, jue, vie, sab, dom]
  final String instructions;
  final int importance; // 1-5
  final String? category;
  final int? treatmentDuration; // días (0 = continuo)
  final String? sideEffects;
  final String reminderStrategy; // 'standard', 'adaptive', 'persistent'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.scheduledTime,
    required this.weekDays,
    this.instructions = '',
    this.importance = 3,
    this.category,
    this.treatmentDuration,
    this.sideEffects,
    this.reminderStrategy = 'standard',
    required this.createdAt,
    this.updatedAt,
  });

  // Para convertir de y a JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    final List<dynamic> weekDaysJson = json['weekDays'];
    final List<bool> weekDaysList = weekDaysJson.map((day) => day as bool).toList();
    
    return Medication(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      scheduledTime: TimeOfDay(
        hour: json['scheduledTimeHour'], 
        minute: json['scheduledTimeMinute']
      ),
      weekDays: weekDaysList,
      instructions: json['instructions'] ?? '',
      importance: json['importance'] ?? 3,
      category: json['category'],
      treatmentDuration: json['treatmentDuration'],
      sideEffects: json['sideEffects'],
      reminderStrategy: json['reminderStrategy'] ?? 'standard',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'scheduledTimeHour': scheduledTime.hour,
      'scheduledTimeMinute': scheduledTime.minute,
      'weekDays': weekDays,
      'instructions': instructions,
      'importance': importance,
      'category': category,
      'treatmentDuration': treatmentDuration,
      'sideEffects': sideEffects,
      'reminderStrategy': reminderStrategy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Método para crear una copia con algunos cambios
  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    TimeOfDay? scheduledTime,
    List<bool>? weekDays,
    String? instructions,
    int? importance,
    String? category,
    int? treatmentDuration,
    String? sideEffects,
    String? reminderStrategy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      weekDays: weekDays ?? this.weekDays,
      instructions: instructions ?? this.instructions,
      importance: importance ?? this.importance,
      category: category ?? this.category,
      treatmentDuration: treatmentDuration ?? this.treatmentDuration,
      sideEffects: sideEffects ?? this.sideEffects,
      reminderStrategy: reminderStrategy ?? this.reminderStrategy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}