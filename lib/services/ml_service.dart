// lib/services/ml_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/ml/isolation_forest.dart';
import 'package:pastillero_inteligente/ml/reinforcement_learning.dart';

class MLService {
  static const String _isolationForestKey = 'isolation_forest_model';
  static const String _reinforcementLearningKey = 'reinforcement_learning_model';
  
  IsolationForest? _isolationForest;
  ReinforcementLearning? _reinforcementLearning;
  
  // Singleton
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();
  
  /// Inicializa los modelos de ML
  Future<void> initialize() async {
    debugPrint('MLService: Inicializando servicio');
    await _loadModels();
  }
  
  /// Entrena el modelo de Isolation Forest para detección de anomalías
  Future<void> trainIsolationForest(
    List<MedicationHistory> history,
    String medicationId,
  ) async {
    debugPrint('MLService: Entrenando modelo Isolation Forest para medicamento $medicationId');
    
    try {
      // Preparar los datos
      final data = IsolationForest.prepareDataFromHistory(history, medicationId);
      
      if (data.isEmpty) {
        debugPrint('MLService: No hay suficientes datos para entrenar el modelo');
        return;
      }
      
      debugPrint('MLService: Datos preparados, entrenando con ${data.length} muestras');
      
      // Crear y entrenar el modelo
      final model = IsolationForest(
        nTrees: 100,
        contaminationFactor: 0.1,
      );
      
      model.fit(data);
      _isolationForest = model;
      
      // Guardar el modelo
      await _saveIsolationForest();
      debugPrint('MLService: Modelo Isolation Forest entrenado y guardado con éxito');
    } catch (e) {
      debugPrint('MLService: Error al entrenar Isolation Forest: $e');
    }
  }
  
  /// Detecta anomalías en la toma de medicamentos
  Map<String, dynamic>? detectAnomalies(
    MedicationHistory medicationEvent,
    String medicationId,
  ) {
    if (_isolationForest == null) {
      debugPrint('MLService: No hay modelo de Isolation Forest disponible');
      return null;
    }
    
    try {
      // Preparar la muestra para el modelo
      final sample = {
        'wasTaken': medicationEvent.wasTaken ? 1.0 : 0.0,
        'deviationMinutes': medicationEvent.deviationMinutes?.toDouble() ?? 0.0,
        'dayOfWeek': medicationEvent.context?.dayOfWeek.toDouble() ?? 
            medicationEvent.scheduledDateTime.weekday.toDouble(),
        'isWeekend': medicationEvent.context?.isWeekend == true ? 1.0 : 0.0,
        'hourOfDay': medicationEvent.scheduledDateTime.hour.toDouble(),
      };
      
      // Predecir si es una anomalía
      final anomalyScore = _isolationForest!.getAnomalyScore(sample);
      final isAnomaly = _isolationForest!.predict(sample) == 1;
      
      debugPrint('MLService: Anomalía detectada: $isAnomaly, Score: $anomalyScore');
      
      if (isAnomaly) {
        final anomalyType = _determineAnomalyType(sample);
        debugPrint('MLService: Tipo de anomalía: $anomalyType');
        
        return {
          'isAnomaly': true,
          'anomalyScore': anomalyScore,
          'anomalyType': anomalyType,
          'details': _generateAnomalyDetails(sample),
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('MLService: Error al detectar anomalías: $e');
      return null;
    }
  }
  
  /// Determina el tipo de anomalía
  String _determineAnomalyType(Map<String, dynamic> sample) {
    // Lógica para identificar el tipo de anomalía
    if (sample['isWeekend'] == 1.0 && sample['wasTaken'] == 0.0) {
      return 'adherence_weekend';
    } else if ((sample['deviationMinutes'] as double).abs() > 60) {
      return 'timing_deviation';
    } else if ((sample['hourOfDay'] < 8 || sample['hourOfDay'] > 22) && sample['wasTaken'] == 0.0) {
      return 'adherence_time_of_day';
    }
    
    return 'general_anomaly';
  }
  
  /// Genera detalles descriptivos sobre la anomalía
  String _generateAnomalyDetails(Map<String, dynamic> sample) {
    // Generar descripción detallada de la anomalía
    switch (_determineAnomalyType(sample)) {
      case 'adherence_weekend':
        return 'Se detectó una omisión durante el fin de semana. Los fines de semana tienes una menor adherencia a la medicación.';
      case 'timing_deviation':
        final deviationMinutes = sample['deviationMinutes'] as double;
        final isLate = deviationMinutes > 0;
        return 'Se detectó una desviación significativa en el horario de toma (${isLate ? '+' : ''}${deviationMinutes.round()} minutos).';
      case 'adherence_time_of_day':
        final hour = (sample['hourOfDay'] as double).round();
        return 'Se detectó una omisión durante un horario atípico ($hour:00). Las tomas en este horario tienen menor adherencia.';
      default:
        return 'Se detectó un patrón inusual en la toma de este medicamento.';
    }
  }
  
  /// Entrena el modelo de Reinforcement Learning para optimización de horarios
  Future<void> trainReinforcementLearning(
    List<MedicationHistory> history,
    List<Medication> medications,
  ) async {
    debugPrint('MLService: Entrenando modelo de Reinforcement Learning');
    
    try {
      if (history.isEmpty || medications.isEmpty) {
        debugPrint('MLService: No hay suficientes datos para entrenar RL');
        return;
      }
      
      // Crear y entrenar el modelo
      final model = ReinforcementLearning(
        learningRate: 0.1,
        discountFactor: 0.9,
        explorationRate: 0.2,
        maxIterations: 1000,
      );
      
      model.train(history, medications);
      _reinforcementLearning = model;
      
      // Guardar el modelo
      await _saveReinforcementLearning();
      debugPrint('MLService: Modelo de Reinforcement Learning entrenado y guardado con éxito');
    } catch (e) {
      debugPrint('MLService: Error al entrenar Reinforcement Learning: $e');
    }
  }
  
  /// Sugiere un mejor horario para un medicamento
  TimeOfDay? suggestBetterTime(Medication medication) {
    if (_reinforcementLearning == null) {
      debugPrint('MLService: No hay modelo de Reinforcement Learning disponible');
      return null;
    }
    
    try {
      // Obtener la predicción
      final suggestedTime = _reinforcementLearning!.predictBestTime(medication);
      debugPrint('MLService: Tiempo sugerido - ${suggestedTime.hour}:${suggestedTime.minute}');
      return suggestedTime;
    } catch (e) {
      debugPrint('MLService: Error al sugerir horario: $e');
      return null;
    }
  }
  
  /// Estima la mejora en adherencia para un horario sugerido
  double estimateAdherenceImprovement(Medication medication, TimeOfDay suggestedTime) {
    if (_reinforcementLearning == null) {
      debugPrint('MLService: No hay modelo de Reinforcement Learning disponible para estimar mejora');
      return 0.0;
    }
    
    try {
      // Estimar adherencia con el horario actual
      final currentAdherence = _reinforcementLearning!.getEstimatedAdherence(
        medication,
        medication.scheduledTime,
      );
      
      // Estimar adherencia con el horario sugerido
      final suggestedAdherence = _reinforcementLearning!.getEstimatedAdherence(
        medication,
        suggestedTime,
      );
      
      // Calcular la mejora
      final improvement = suggestedAdherence - currentAdherence;
      debugPrint('MLService: Mejora estimada en adherencia: $improvement%');
      return improvement;
    } catch (e) {
      debugPrint('MLService: Error al estimar mejora de adherencia: $e');
      return 0.0;
    }
  }
  
  /// Analiza patrones en el historial para un medicamento específico
  Map<String, dynamic> analyzeMedicationPatterns(
    List<MedicationHistory> history,
    String medicationId,
  ) {
    debugPrint('MLService: Analizando patrones para medicamento $medicationId');
    
    // Filtrar historial para este medicamento
    final medicationHistory = history
        .where((item) => item.medicationId == medicationId)
        .toList();
    
    if (medicationHistory.isEmpty) {
      debugPrint('MLService: No hay historial para este medicamento');
      return {
        'hasPatterns': false,
        'adherence': 0,
        'patterns': [],
      };
    }
    
    // Calcular adherencia global
    final totalItems = medicationHistory.length;
    final takenItems = medicationHistory.where((item) => item.wasTaken).length;
    final adherence = (takenItems / totalItems) * 100;
    
    debugPrint('MLService: Adherencia global: $adherence% ($takenItems/$totalItems)');
    
    // Lista para almacenar patrones detectados
    final List<Map<String, dynamic>> patterns = [];
    
    // Analizar patrones por día de la semana
    final Map<int, List<MedicationHistory>> dayGroups = {};
    for (var item in medicationHistory) {
      final day = item.scheduledDateTime.weekday;
      if (!dayGroups.containsKey(day)) {
        dayGroups[day] = [];
      }
      dayGroups[day]!.add(item);
    }
    
    // Calcular adherencia por día
    final Map<int, double> dayAdherences = {};
    for (var entry in dayGroups.entries) {
      final items = entry.value;
      final takenCount = items.where((item) => item.wasTaken).length;
      dayAdherences[entry.key] = (takenCount / items.length) * 100;
    }
    
    // Detectar días con baja adherencia
    for (var entry in dayAdherences.entries) {
      if (entry.value < adherence - 20) { // 20% menos que el promedio
        final dayName = _getDayName(entry.key);
        patterns.add({
          'tipo': 'adherencia',
          'descripcion': 'Los $dayName tienes una adherencia ${entry.value.round()}% menor al promedio',
          'sugerencia': 'Configura recordatorios adicionales para los $dayName',
          'accion': 'recordar',
          'confianza': 85 + (adherence - entry.value).round(),
        });
      }
    }
    
    // Analizar patrones de tiempo
    final takenWithDeviation = medicationHistory
        .where((item) => item.wasTaken && item.deviationMinutes != null)
        .toList();
    
    if (takenWithDeviation.isNotEmpty) {
      // Calcular desviación promedio
      int totalDeviation = 0;
      for (var item in takenWithDeviation) {
        totalDeviation += item.deviationMinutes ?? 0;
      }
      
      final avgDeviation = totalDeviation / takenWithDeviation.length;
      
      // Si hay una desviación consistente, sugerir ajuste
      if (avgDeviation.abs() >= 10) { // 10 minutos o más
        final direction = avgDeviation > 0 ? 'después' : 'antes';
        patterns.add({
          'tipo': 'tiempo',
          'descripcion': 'Sueles tomar este medicamento ${avgDeviation.abs().round()} minutos $direction de lo programado',
          'sugerencia': 'Reajustar el horario para reflejar tu patrón real',
          'accion': 'ajustar',
          'confianza': 80 + math.min(avgDeviation.abs(), 40).round(),
        });
      }
    }
    
    // Analizar patrones contextuales
    final contextos = medicationHistory
        .where((item) => item.context != null)
        .map((item) => item.context!)
        .toList();
    
    if (contextos.isNotEmpty) {
      // Verificar si hay patrones relacionados con la ubicación
      final ubicaciones = contextos
          .where((ctx) => ctx.location != null)
          .map((ctx) => ctx.location!)
          .toList();
      
      if (ubicaciones.isNotEmpty) {
        // Contar ocurrencias de cada ubicación
        final Map<String, int> ubicacionCount = {};
        for (var ubicacion in ubicaciones) {
          ubicacionCount[ubicacion] = (ubicacionCount[ubicacion] ?? 0) + 1;
        }
        
        // Encontrar la ubicación más común
        String? ubicacionComun;
        int maxCount = 0;
        for (var entry in ubicacionCount.entries) {
          if (entry.value > maxCount) {
            maxCount = entry.value;
            ubicacionComun = entry.key;
          }
        }
        
        // Verificar si hay omisiones cuando no está en la ubicación común
        if (ubicacionComun != null) {
          final itemsEnUbicacionComun = medicationHistory
              .where((item) => 
                  item.context?.location == ubicacionComun)
              .toList();
          
          final itemsFueraUbicacionComun = medicationHistory
              .where((item) => 
                  item.context?.location != null &&
                  item.context?.location != ubicacionComun)
              .toList();
          
          if (itemsFueraUbicacionComun.isNotEmpty) {
            final adherenciaComun = itemsEnUbicacionComun
                .where((item) => item.wasTaken)
                .length / itemsEnUbicacionComun.length;
            
            final adherenciaFuera = itemsFueraUbicacionComun
                .where((item) => item.wasTaken)
                .length / itemsFueraUbicacionComun.length;
            
            if (adherenciaComun - adherenciaFuera > 0.2) { // 20% de diferencia
              patterns.add({
                'tipo': 'contexto',
                'descripcion': 'Mayor probabilidad de omisión cuando no estás en $ubicacionComun',
                'sugerencia': 'Preparar dosis para llevar cuando salgas de $ubicacionComun',
                'accion': 'informar',
                'confianza': 75 + ((adherenciaComun - adherenciaFuera) * 100).round(),
              });
            }
          }
        }
      }
    }
    
    debugPrint('MLService: Se detectaron ${patterns.length} patrones');
    
    return {
      'hasPatterns': patterns.isNotEmpty,
      'adherence': adherence.round(),
      'patterns': patterns,
    };
  }
  
  /// Guarda el modelo de Isolation Forest
  Future<void> _saveIsolationForest() async {
    if (_isolationForest == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_isolationForest!.toJson());
      await prefs.setString(_isolationForestKey, json);
      debugPrint('MLService: Modelo Isolation Forest guardado localmente');
    } catch (e) {
      debugPrint('MLService: Error al guardar el modelo de Isolation Forest: $e');
    }
  }
  
  /// Guarda el modelo de Reinforcement Learning
  Future<void> _saveReinforcementLearning() async {
    if (_reinforcementLearning == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_reinforcementLearning!.toJson());
      await prefs.setString(_reinforcementLearningKey, json);
      debugPrint('MLService: Modelo Reinforcement Learning guardado localmente');
    } catch (e) {
      debugPrint('MLService: Error al guardar el modelo de Reinforcement Learning: $e');
    }
  }
  
  /// Carga los modelos almacenados
  Future<void> _loadModels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar modelo de Isolation Forest
      final ifJson = prefs.getString(_isolationForestKey);
      if (ifJson != null) {
        final map = jsonDecode(ifJson) as Map<String, dynamic>;
        _isolationForest = IsolationForest.fromJson(map);
        debugPrint('MLService: Modelo Isolation Forest cargado desde almacenamiento local');
      } else {
        debugPrint('MLService: No hay modelo de Isolation Forest guardado localmente');
      }
      
      // Cargar modelo de Reinforcement Learning
      final rlJson = prefs.getString(_reinforcementLearningKey);
      if (rlJson != null) {
        final map = jsonDecode(rlJson) as Map<String, dynamic>;
        _reinforcementLearning = ReinforcementLearning.fromJson(map);
        debugPrint('MLService: Modelo Reinforcement Learning cargado desde almacenamiento local');
      } else {
        debugPrint('MLService: No hay modelo de Reinforcement Learning guardado localmente');
      }
    } catch (e) {
      debugPrint('MLService: Error al cargar los modelos: $e');
    }
  }
  
  /// Convierte día de la semana (1-7) a nombre
  String _getDayName(int day) {
    switch (day) {
      case 1: return 'lunes';
      case 2: return 'martes';
      case 3: return 'miércoles';
      case 4: return 'jueves';
      case 5: return 'viernes';
      case 6: return 'sábado';
      case 7: return 'domingo';
      default: return 'día';
    }
  }
}