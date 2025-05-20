// lib/providers/medication_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/services/api_service.dart';
import 'package:pastillero_inteligente/services/ml_service.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';

class MedicationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final MLService _mlService = MLService();
  final _uuid = Uuid();
  
  // Lista de medicamentos
  List<Medication> _medications = [];
  List<Medication> get medications => [..._medications];
  
  // Historial de medicamentos
  List<MedicationHistory> _history = [];
  List<MedicationHistory> get history => [..._history];
  
  // Estados
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  // Constructor
  MedicationProvider() {
    // Inicializar el servicio de ML
    _initializeMlService();
    
    // Configurar el ID de usuario desde AuthService
    final authService = AuthService();
    if (authService.userId != null) {
      // Esto es solo para garantizar que se use la referencia a AuthService
      // El API service ahora obtiene el userId dinámicamente
      print('Usuario autenticado con ID: ${authService.userId}');
    }
  }
  
  // Inicializar el servicio de ML
  Future<void> _initializeMlService() async {
    await _mlService.initialize();
  }
  
  // Obtener medicamentos actuales
  Future<void> fetchMedications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _medications = await _apiService.getMedications();
      await _loadMedicationHistory();
      _isLoading = false;
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
  
  // Cargar historial de medicamentos
  Future<void> _loadMedicationHistory() async {
    try {
      _history = await _apiService.getMedicationHistory();
      notifyListeners();
    } catch (error) {
      print('Error al cargar historial: $error');
    }
  }
  
  // Añadir medicamento
  Future<bool> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newMedication = await _apiService.addMedication(medication);
      _medications.add(newMedication);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Actualizar medicamento
  Future<bool> updateMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _apiService.updateMedication(medication);
      
      if (success) {
        final index = _medications.indexWhere((med) => med.id == medication.id);
        if (index != -1) {
          _medications[index] = medication;
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Eliminar medicamento
  Future<bool> deleteMedication(String medicationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _apiService.deleteMedication(medicationId);
      
      if (success) {
        _medications.removeWhere((med) => med.id == medicationId);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Registrar toma de medicamento
  Future<bool> recordMedicationTaken(String medicationId, DateTime takenTime, MedicationContext? context) async {
    try {
      // Encontrar el medicamento
      final medication = _medications.firstWhere((med) => med.id == medicationId);
      
      // Encontrar la fecha programada más cercana
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year, 
        now.month, 
        now.day,
        medication.scheduledTime.hour,
        medication.scheduledTime.minute,
      );
      
      // Calcular desviación en minutos
      final deviationMinutes = takenTime.difference(scheduledDateTime).inMinutes;
      
      // Crear registro en el historial
      final historyRecord = MedicationHistory(
        id: _uuid.v4(),
        medicationId: medicationId,
        scheduledDateTime: scheduledDateTime,
        actualTakenTime: takenTime,
        wasTaken: true,
        deviationMinutes: deviationMinutes,
        context: context,
        createdAt: DateTime.now(),
      );
      
      // Guardar el registro
      final success = await _apiService.saveMedicationHistory(historyRecord);
      
      if (success) {
        _history.add(historyRecord);
        
        // Detectar posibles anomalías
        final anomaly = _mlService.detectAnomalies(historyRecord, medicationId);
        if (anomaly != null && anomaly['isAnomaly'] == true) {
          // Aquí podrías implementar alguna lógica para mostrar alertas o
          // guardar la anomalía en la base de datos
          print('Anomalía detectada: ${anomaly['details']}');
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (error) {
      print('Error recording medication taken: $error');
      return false;
    }
  }
  
  // Registrar medicamento no tomado
  Future<bool> recordMedicationSkipped(String medicationId, String? reason) async {
    try {
      // Encontrar el medicamento
      final medication = _medications.firstWhere((med) => med.id == medicationId);
      
      // Fecha programada
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year, 
        now.month, 
        now.day,
        medication.scheduledTime.hour,
        medication.scheduledTime.minute,
      );
      
      // Crear registro en el historial
      final historyRecord = MedicationHistory(
        id: _uuid.v4(),
        medicationId: medicationId,
        scheduledDateTime: scheduledDateTime,
        wasTaken: false,
        reasonNotTaken: reason,
        createdAt: DateTime.now(),
      );
      
      // Guardar el registro
      final success = await _apiService.saveMedicationHistory(historyRecord);
      
      if (success) {
        _history.add(historyRecord);
        notifyListeners();
      }
      
      return success;
    } catch (error) {
      print('Error recording medication skipped: $error');
      return false;
    }
  }
  
  // Obtener medicamentos para hoy
  List<Medication> getMedicationsForToday() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday - 1; // 0-6 (lunes-domingo)
    
    return _medications.where((med) => med.weekDays[dayOfWeek]).toList();
  }
  
  // Obtener medicamentos próximos
  List<Medication> getUpcomingMedications() {
    final medicationsForToday = getMedicationsForToday();
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    
    // Ordenar por proximidad a la hora actual
    medicationsForToday.sort((a, b) {
      final aMinutes = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
      final bMinutes = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
      final currentMinutes = currentTime.hour * 60 + currentTime.minute;
      
      final aDiff = (aMinutes >= currentMinutes) 
          ? aMinutes - currentMinutes 
          : aMinutes - currentMinutes + 24 * 60;
      
      final bDiff = (bMinutes >= currentMinutes) 
          ? bMinutes - currentMinutes 
          : bMinutes - currentMinutes + 24 * 60;
          
      return aDiff.compareTo(bDiff);
    });
    
    return medicationsForToday;
  }
  
  // Obtener porcentaje de adherencia
  double getAdherencePercentage({int? days}) {
    if (_history.isEmpty) return 0.0;
    
    List<MedicationHistory> filteredHistory = [..._history];
    
    // Filtrar por número de días si se especifica
    if (days != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      filteredHistory = filteredHistory
          .where((record) => record.scheduledDateTime.isAfter(cutoffDate))
          .toList();
    }
    
    if (filteredHistory.isEmpty) return 0.0;
    
    final totalRecords = filteredHistory.length;
    final takenRecords = filteredHistory.where((record) => record.wasTaken).length;
    
    return (takenRecords / totalRecords) * 100;
  }
  
  // Entrenar modelos de ML con los datos disponibles
  Future<void> trainMlModels() async {
    if (_history.length < 10) {
      // No hay suficientes datos para entrenar
      return;
    }
    
    try {
      // Entrenar Isolation Forest para detectar anomalías
      for (var medication in _medications) {
        await _mlService.trainIsolationForest(_history, medication.id);
      }
      
      // Entrenar Reinforcement Learning para optimizar horarios
      await _mlService.trainReinforcementLearning(_history, _medications);
    } catch (error) {
      print('Error al entrenar modelos de ML: $error');
    }
  }
  
  // Obtener sugerencia de mejor horario para un medicamento
  TimeOfDay? getSuggestedTime(Medication medication) {
    return _mlService.suggestBetterTime(medication);
  }
  
  // Obtener patrones detectados para un medicamento
  Map<String, dynamic> getMedicationPatterns(String medicationId) {
    return _mlService.analyzeMedicationPatterns(_history, medicationId);
  }
  
  // Ejecutar diagnóstico de conexión a la API
  Future<Map<String, dynamic>> runApiDiagnostics() async {
    return await _apiService.diagnosisApiConnection();
  }
}