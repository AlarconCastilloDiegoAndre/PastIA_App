// lib/models/medication_history_model.dart

class MedicationHistory {
  final String id;
  final String medicationId;
  final DateTime scheduledDateTime;
  final DateTime? actualTakenTime;
  final bool wasTaken;
  final String? reasonNotTaken;
  final MedicationContext? context;
  final int? deviationMinutes; // Minutos antes (-) o después (+)
  final DateTime createdAt;

  MedicationHistory({
    required this.id,
    required this.medicationId,
    required this.scheduledDateTime,
    this.actualTakenTime,
    required this.wasTaken,
    this.reasonNotTaken,
    this.context,
    this.deviationMinutes,
    required this.createdAt,
  });

  factory MedicationHistory.fromJson(Map<String, dynamic> json) {
    return MedicationHistory(
      id: json['id'],
      medicationId: json['medicationId'],
      scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
      actualTakenTime: json['actualTakenTime'] != null 
          ? DateTime.parse(json['actualTakenTime']) 
          : null,
      wasTaken: json['wasTaken'],
      reasonNotTaken: json['reasonNotTaken'],
      context: json['context'] != null 
          ? MedicationContext.fromJson(json['context']) 
          : null,
      deviationMinutes: json['deviationMinutes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicationId': medicationId,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'actualTakenTime': actualTakenTime?.toIso8601String(),
      'wasTaken': wasTaken,
      'reasonNotTaken': reasonNotTaken,
      'context': context?.toJson(),
      'deviationMinutes': deviationMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MedicationContext {
  final String? location;
  final String? activity;
  final String? mood;
  final int adherenceStreak;
  final int? timeDeviation;
  final int dayOfWeek; // 1-7 (lunes-domingo)
  final bool isWeekend;
  final bool isHoliday;
  final bool wasTravelDay;

  MedicationContext({
    this.location,
    this.activity,
    this.mood,
    required this.adherenceStreak,
    this.timeDeviation,
    required this.dayOfWeek,
    required this.isWeekend,
    this.isHoliday = false,
    this.wasTravelDay = false,
  });

  factory MedicationContext.fromJson(Map<String, dynamic> json) {
    return MedicationContext(
      location: json['location'],
      activity: json['activity'],
      mood: json['mood'],
      adherenceStreak: json['adherenceStreak'],
      timeDeviation: json['timeDeviation'],
      dayOfWeek: json['dayOfWeek'],
      isWeekend: json['isWeekend'],
      isHoliday: json['isHoliday'] ?? false,
      wasTravelDay: json['wasTravelDay'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'activity': activity,
      'mood': mood,
      'adherenceStreak': adherenceStreak,
      'timeDeviation': timeDeviation,
      'dayOfWeek': dayOfWeek,
      'isWeekend': isWeekend,
      'isHoliday': isHoliday,
      'wasTravelDay': wasTravelDay,
    };
  }
}