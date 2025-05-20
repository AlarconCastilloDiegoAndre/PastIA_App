// lib/ml/reinforcement_learning.dart
import 'dart:math';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:flutter/material.dart';

/// Implementación de un algoritmo simple de Reinforcement Learning
/// para optimización de horarios de medicamentos
class ReinforcementLearning {
  // Hiperparámetros del modelo
  final double _learningRate; // Tasa de aprendizaje (alpha)
  final double _discountFactor; // Factor de descuento (gamma)
  final double _explorationRate; // Tasa de exploración (epsilon)
  final int _maxIterations; // Número máximo de iteraciones
  
  // Estado del modelo
  Map<String, Map<String, double>> _qTable = {}; // Tabla Q para almacenar valores estado-acción
  bool _isTrained = false;
  
  ReinforcementLearning({
    double learningRate = 0.1,
    double discountFactor = 0.9,
    double explorationRate = 0.2,
    int maxIterations = 1000,
  }) : _learningRate = learningRate,
       _discountFactor = discountFactor,
       _explorationRate = explorationRate,
       _maxIterations = maxIterations;
  
  /// Entrena el modelo usando el historial de medicamentos para optimizar horarios
  void train(List<MedicationHistory> history, List<Medication> medications) {
    final random = Random();
    
    // Inicializar la tabla Q
    _initializeQTable(medications);
    
    // Iterar para entrenar el modelo
    for (int iteration = 0; iteration < _maxIterations; iteration++) {
      // Para cada medicamento
      for (var medication in medications) {
        // Obtener el historial para este medicamento
        final medHistory = history
            .where((item) => item.medicationId == medication.id)
            .toList();
        
        if (medHistory.isEmpty) continue;
        
        // Estado actual (hora actual programada)
        final currentHour = medication.scheduledTime.hour;
        final currentMinute = medication.scheduledTime.minute;
        final currentState = '$currentHour:$currentMinute';
        
        // Exploración vs explotación
        String action;
        if (random.nextDouble() < _explorationRate) {
          // Exploración: elegir una acción aleatoria
          final possibleActions = _getActions(currentHour, currentMinute);
          action = possibleActions[random.nextInt(possibleActions.length)];
        } else {
          // Explotación: elegir la mejor acción según la tabla Q
          action = _getBestAction(currentState);
        }
        
        // Simular la toma del medicamento en este nuevo horario
        final actionHourMinute = action.split(':');
        final newHour = int.parse(actionHourMinute[0]);
        final newMinute = int.parse(actionHourMinute[1]);
        
        // Calcular recompensa
        final reward = _calculateReward(medHistory, medication, newHour, newMinute);
        
        // Actualizar la tabla Q
        _updateQValue(currentState, action, reward);
      }
    }
    
    _isTrained = true;
  }
  
  /// Predice la mejor hora para tomar un medicamento
  TimeOfDay predictBestTime(Medication medication) {
    if (!_isTrained) {
      throw Exception('El modelo debe ser entrenado primero');
    }
    
    // Estado actual
    final currentHour = medication.scheduledTime.hour;
    final currentMinute = medication.scheduledTime.minute;
    final currentState = '$currentHour:$currentMinute';
    
    // Obtener la mejor acción
    final bestAction = _getBestAction(currentState);
    final actionParts = bestAction.split(':');
    
    return TimeOfDay(
      hour: int.parse(actionParts[0]),
      minute: int.parse(actionParts[1]),
    );
  }
  
  /// Obtener la adherencia estimada para un horario específico
  double getEstimatedAdherence(Medication medication, TimeOfDay time) {
    if (!_isTrained) {
      throw Exception('El modelo debe ser entrenado primero');
    }
    
    // Estado actual
    final currentHour = medication.scheduledTime.hour;
    final currentMinute = medication.scheduledTime.minute;
    final currentState = '$currentHour:$currentMinute';
    
    // Acción propuesta
    final action = '${time.hour}:${time.minute}';
    
    // Obtener el valor Q (estimación de adherencia)
    if (_qTable.containsKey(currentState) && _qTable[currentState]!.containsKey(action)) {
      return _qTable[currentState]![action]! * 100; // Convertir a porcentaje
    }
    
    // Si no existe, devolver la adherencia actual (sin cambios)
    return 70.0; // Valor por defecto
  }
  
  /// Inicializar la tabla Q con valores por defecto
  void _initializeQTable(List<Medication> medications) {
    _qTable = {};
    
    for (var medication in medications) {
      final hour = medication.scheduledTime.hour;
      final minute = medication.scheduledTime.minute;
      final state = '$hour:$minute';
      
      if (!_qTable.containsKey(state)) {
        _qTable[state] = {};
      }
      
      // Generar acciones posibles (variaciones de horario)
      final actions = _getActions(hour, minute);
      
      for (var action in actions) {
        _qTable[state]![action] = 0.5; // Valor inicial optimista
      }
    }
  }
  
  /// Genera acciones posibles (variaciones de horario)
  List<String> _getActions(int hour, int minute) {
    final List<String> actions = [];
    
    // Horario actual
    actions.add('$hour:$minute');
    
    // Variaciones de +/- 15, 30, 45, 60 minutos
    for (int delta in [-60, -45, -30, -15, 15, 30, 45, 60]) {
      int newMinute = minute + delta;
      int newHour = hour;
      
      while (newMinute >= 60) {
        newMinute -= 60;
        newHour = (newHour + 1) % 24;
      }
      
      while (newMinute < 0) {
        newMinute += 60;
        newHour = (newHour - 1) % 24;
        if (newHour < 0) newHour += 24;
      }
      
      actions.add('$newHour:$newMinute');
    }
    
    return actions;
  }
  
  /// Obtiene la mejor acción para un estado dado
  String _getBestAction(String state) {
    if (!_qTable.containsKey(state) || _qTable[state]!.isEmpty) {
      // Si no hay información, devolver el mismo estado como acción
      return state;
    }
    
    // Encontrar la acción con el mayor valor Q
    String bestAction = _qTable[state]!.keys.first;
    double maxQ = _qTable[state]![bestAction]!;
    
    for (var entry in _qTable[state]!.entries) {
      if (entry.value > maxQ) {
        maxQ = entry.value;
        bestAction = entry.key;
      }
    }
    
    return bestAction;
  }
  
  /// Actualiza el valor Q para un par estado-acción
  void _updateQValue(String state, String action, double reward) {
    if (!_qTable.containsKey(state)) {
      _qTable[state] = {};
    }
    
    if (!_qTable[state]!.containsKey(action)) {
      _qTable[state]![action] = 0.0;
    }
    
    // Q(s,a) = Q(s,a) + alpha * (reward + gamma * max_a' Q(s',a') - Q(s,a))
    // En esta implementación simplificada, no consideramos el estado siguiente
    _qTable[state]![action] = _qTable[state]![action]! + 
        _learningRate * (reward - _qTable[state]![action]!);
  }
  
  /// Calcula la recompensa para una acción
  double _calculateReward(
    List<MedicationHistory> history,
    Medication medication,
    int newHour,
    int newMinute,
  ) {
    // Calcular adherencia actual
    final currentAdherence = _calculateAdherence(history);
    
    // Estimar adherencia con el nuevo horario
    final estimatedAdherence = _estimateNewAdherence(
      history,
      medication,
      newHour,
      newMinute,
    );
    
    // La recompensa es la mejora en adherencia
    return estimatedAdherence - currentAdherence;
  }
  
  /// Calcula la adherencia actual basada en el historial
  double _calculateAdherence(List<MedicationHistory> history) {
    if (history.isEmpty) return 0.5; // Valor por defecto
    
    int takenCount = 0;
    for (var item in history) {
      if (item.wasTaken) takenCount++;
    }
    
    return takenCount / history.length;
  }
  
  /// Estima la adherencia con un nuevo horario
  double _estimateNewAdherence(
    List<MedicationHistory> history,
    Medication medication,
    int newHour,
    int newMinute,
  ) {
    // En una implementación real, esto usaría características como:
    // - Patrones de adherencia por hora del día
    // - Actividades habituales a esa hora
    // - Días de la semana
    // - Etc.
    
    // Simulación simple: si el nuevo horario está entre las 8 y las 21,
    // asumimos mejor adherencia
    if (newHour >= 8 && newHour <= 21) {
      // Horario "óptimo"
      return min(1.0, _calculateAdherence(history) + 0.1);
    } else {
      // Horario no óptimo
      return max(0.0, _calculateAdherence(history) - 0.1);
    }
  }
  
  /// Analiza patrones en el historial para mejorar la estimación
  Map<String, dynamic> analyzePatterns(List<MedicationHistory> history) {
    if (history.isEmpty) {
      return {
        'bestTimeOfDay': [8, 12, 18], // Horarios por defecto
        'worstDays': [], // No hay días malos por defecto
        'averageDeviation': 0, // Sin desviación
      };
    }
    
    // Agrupar por hora del día
    final Map<int, List<MedicationHistory>> hourGroups = {};
    for (var item in history) {
      final hour = item.scheduledDateTime.hour;
      if (!hourGroups.containsKey(hour)) {
        hourGroups[hour] = [];
      }
      hourGroups[hour]!.add(item);
    }
    
    // Encontrar las mejores horas (mayor adherencia)
    final List<MapEntry<int, double>> hourAdherences = hourGroups.entries.map((entry) {
      final hour = entry.key;
      final items = entry.value;
      final takenCount = items.where((item) => item.wasTaken).length;
      return MapEntry(hour, takenCount / items.length);
    }).toList();
    
    hourAdherences.sort((a, b) => b.value.compareTo(a.value));
    
    // Las 3 mejores horas
    final bestTimes = hourAdherences.take(3).map((e) => e.key).toList();
    
    // Analizar días de la semana
    final Map<int, List<MedicationHistory>> dayGroups = {};
    for (var item in history) {
      final day = item.scheduledDateTime.weekday;
      if (!dayGroups.containsKey(day)) {
        dayGroups[day] = [];
      }
      dayGroups[day]!.add(item);
    }
    
    // Encontrar los peores días (menor adherencia)
    final List<MapEntry<int, double>> dayAdherences = dayGroups.entries.map((entry) {
      final day = entry.key;
      final items = entry.value;
      final takenCount = items.where((item) => item.wasTaken).length;
      return MapEntry(day, takenCount / items.length);
    }).toList();
    
    dayAdherences.sort((a, b) => a.value.compareTo(b.value));
    
    // Días con adherencia menor al 70%
    final worstDays = dayAdherences
        .where((e) => e.value < 0.7)
        .map((e) => e.key)
        .toList();
    
    // Calcular desviación promedio
    final takenItems = history
        .where((item) => item.wasTaken && item.deviationMinutes != null)
        .toList();
    
    int totalDeviation = 0;
    for (var item in takenItems) {
      totalDeviation += item.deviationMinutes?.abs() ?? 0;
    }
    
    final avgDeviation = takenItems.isNotEmpty
        ? totalDeviation / takenItems.length
        : 0;
    
    return {
      'bestTimeOfDay': bestTimes,
      'worstDays': worstDays,
      'averageDeviation': avgDeviation,
    };
  }
  
  /// Serializa el modelo a un mapa
  Map<String, dynamic> toJson() {
    return {
      'learningRate': _learningRate,
      'discountFactor': _discountFactor,
      'explorationRate': _explorationRate,
      'maxIterations': _maxIterations,
      'qTable': _qTable,
      'isTrained': _isTrained,
    };
  }
  
  /// Deserializa el modelo desde un mapa
  factory ReinforcementLearning.fromJson(Map<String, dynamic> json) {
    final model = ReinforcementLearning(
      learningRate: json['learningRate'],
      discountFactor: json['discountFactor'],
      explorationRate: json['explorationRate'],
      maxIterations: json['maxIterations'],
    );
    
    model._qTable = {};
    final qTableJson = json['qTable'] as Map<String, dynamic>;
    for (var state in qTableJson.keys) {
      model._qTable[state] = {};
      final actionsJson = qTableJson[state] as Map<String, dynamic>;
      for (var action in actionsJson.keys) {
        model._qTable[state]![action] = actionsJson[action];
      }
    }
    
    model._isTrained = json['isTrained'];
    
    return model;
  }
}