// lib/services/api_service.dart (encabezado actualizado)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';

class ApiService {
  // URL base de la API Azure Functions
  final String baseUrl = 'https://pastia-api.azurewebsites.net/api';
  
  // Clave de función (obtenida del portal de Azure)
  final String functionKey = '0Mup-nhcbqOTrX70vMP04a_cNYEHUjddy_Xm_HfOtVvAzFuMAWtnw==';
  
  // Encabezados con la clave de autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-functions-key': functionKey
  };
  
  // Obtener el ID de usuario actual desde AuthService
  String get userId {
    final authService = AuthService();
    return authService.userId ?? 'USR001';
  }
  // Método para obtener medicamentos
  Future<List<Medication>> getMedications() async {
    try {
      debugPrint('ApiService: Obteniendo medicamentos para userId=$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/GetMedicaments?userId=$userId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('ApiService: Respuesta de GetMedicaments - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('ApiService: Se obtuvieron ${data.length} medicamentos');
        return _convertToMedications(data);
      } else {
        debugPrint('ApiService: Error al obtener medicamentos - código ${response.statusCode}: ${response.body}');
        // Si falla la API, podríamos intentar obtener datos locales
        final localMeds = await _getLocalMedications();
        if (localMeds.isNotEmpty) {
          debugPrint('ApiService: Retornando ${localMeds.length} medicamentos guardados localmente');
          return localMeds;
        }
        throw Exception('Error al obtener medicamentos: ${response.statusCode}');
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en getMedications: $error');
      
      // En caso de error, intentar recuperar datos locales
      final localMeds = await _getLocalMedications();
      if (localMeds.isNotEmpty) {
        debugPrint('ApiService: Retornando ${localMeds.length} medicamentos guardados localmente');
        return localMeds;
      }
      
      rethrow;
    }
  }
  
  // Método para guardar medicamentos localmente
  Future<void> _saveLocalMedications(List<Medication> medications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> medicationList = medications.map((m) => m.toJson()).toList();
      await prefs.setString('medications_data', jsonEncode(medicationList));
      debugPrint('ApiService: Medicamentos guardados localmente');
    } catch (e) {
      debugPrint('ApiService: Error al guardar medicamentos localmente: $e');
    }
  }
  
  // Método para obtener medicamentos guardados localmente
  Future<List<Medication>> _getLocalMedications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final medicationsJson = prefs.getString('medications_data');
      
      if (medicationsJson != null) {
        final List<dynamic> data = jsonDecode(medicationsJson);
        debugPrint('ApiService: Recuperados ${data.length} medicamentos locales');
        return data.map((item) => Medication.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('ApiService: Error al obtener medicamentos locales: $e');
      return [];
    }
  }
  
  // Método para añadir un medicamento
  Future<Medication> addMedication(Medication medication) async {
    try {
      debugPrint('ApiService: Añadiendo medicamento: ${medication.name}');
      
      final medicationJson = _convertMedicationToJson(medication);
      debugPrint('ApiService: JSON para enviar: ${jsonEncode(medicationJson)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/AddMedication'),
        headers: _headers,
        body: json.encode(medicationJson),
      ).timeout(const Duration(seconds: 20));
      
      debugPrint('ApiService: Respuesta de AddMedication - Status: ${response.statusCode}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Usamos el ID devuelto si está disponible o mantenemos el original
        final responseData = json.decode(response.body);
        debugPrint('ApiService: Respuesta: ${response.body}');
        
        final medicationId = responseData['id'] ?? medication.id;
        
        // Crear una copia del medicamento con el ID actualizado
        final updatedMedication = medication.copyWith(id: medicationId);
        
        // Actualizar la caché local
        final localMedications = await _getLocalMedications();
        localMedications.add(updatedMedication);
        await _saveLocalMedications(localMedications);
        
        return updatedMedication;
      } else {
        debugPrint('ApiService: Error de respuesta: ${response.body}');
        
        // En caso de fallo, guardar localmente de todos modos
        final localMedications = await _getLocalMedications();
        localMedications.add(medication);
        await _saveLocalMedications(localMedications);
        
        throw Exception('Error al añadir medicamento: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en addMedication: $error');
      
      // En caso de error de conexión, guardar localmente
      try {
        final localMedications = await _getLocalMedications();
        localMedications.add(medication);
        await _saveLocalMedications(localMedications);
        debugPrint('ApiService: Medicamento guardado localmente después de error');
      } catch (e) {
        debugPrint('ApiService: Error adicional al guardar localmente: $e');
      }
      
      rethrow;
    }
  }
  
  // Método para actualizar un medicamento
  Future<bool> updateMedication(Medication medication) async {
    try {
      debugPrint('ApiService: Actualizando medicamento: ${medication.id}');
      
      final medicationJson = _convertMedicationToJson(medication);
      
      final response = await http.put(
        Uri.parse('$baseUrl/UpdateMedication'),
        headers: _headers,
        body: json.encode(medicationJson),
      ).timeout(const Duration(seconds: 20));
      
      debugPrint('ApiService: Respuesta de UpdateMedication - Status: ${response.statusCode}');
      
      // Actualizar la versión local independientemente de la respuesta del servidor
      try {
        final localMedications = await _getLocalMedications();
        final index = localMedications.indexWhere((med) => med.id == medication.id);
        
        if (index != -1) {
          localMedications[index] = medication;
        } else {
          localMedications.add(medication);
        }
        
        await _saveLocalMedications(localMedications);
        debugPrint('ApiService: Medicamento actualizado localmente');
      } catch (e) {
        debugPrint('ApiService: Error al actualizar medicamento localmente: $e');
      }
      
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('ApiService: Excepción en updateMedication: $error');
      
      // Actualizar localmente en caso de error
      try {
        final localMedications = await _getLocalMedications();
        final index = localMedications.indexWhere((med) => med.id == medication.id);
        
        if (index != -1) {
          localMedications[index] = medication;
          await _saveLocalMedications(localMedications);
          debugPrint('ApiService: Medicamento actualizado localmente después de error');
        }
      } catch (e) {
        debugPrint('ApiService: Error adicional al actualizar localmente: $e');
      }
      
      return false;
    }
  }
  
  // Método para eliminar un medicamento
  Future<bool> deleteMedication(String medicationId) async {
    try {
      debugPrint('ApiService: Eliminando medicamento: $medicationId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/DeleteMedication?id=$medicationId&userId=$userId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('ApiService: Respuesta de DeleteMedication - Status: ${response.statusCode}');
      
      // Actualizar la versión local independientemente de la respuesta del servidor
      try {
        final localMedications = await _getLocalMedications();
        localMedications.removeWhere((med) => med.id == medicationId);
        await _saveLocalMedications(localMedications);
        debugPrint('ApiService: Medicamento eliminado localmente');
      } catch (e) {
        debugPrint('ApiService: Error al eliminar medicamento localmente: $e');
      }
      
      return response.statusCode == 200;
    } catch (error) {
      debugPrint('ApiService: Excepción en deleteMedication: $error');
      
      // Eliminar localmente en caso de error
      try {
        final localMedications = await _getLocalMedications();
        localMedications.removeWhere((med) => med.id == medicationId);
        await _saveLocalMedications(localMedications);
        debugPrint('ApiService: Medicamento eliminado localmente después de error');
        return true; // Podemos considerar exitosa la operación local
      } catch (e) {
        debugPrint('ApiService: Error adicional al eliminar localmente: $e');
      }
      
      return false;
    }
  }
  
  // Métodos para el historial de medicamentos
  Future<List<MedicationHistory>> getMedicationHistory({String? medicationId, int days = 30}) async {
    try {
      debugPrint('ApiService: Obteniendo historial para userId=$userId, medicationId=$medicationId, days=$days');
      
      // Construir URL con parámetros
      String url = '$baseUrl/GetMedicationHistory?userId=$userId';
      if (medicationId != null) {
        url += '&medicationId=$medicationId';
      }
      url += '&days=$days';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('ApiService: Respuesta de GetMedicationHistory - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('ApiService: Se obtuvieron ${data.length} registros de historial');
        
        final history = data.map((item) => MedicationHistory.fromJson(item)).toList();
        
        // Guardar localmente para tener respaldo
        await _saveLocalMedicationHistory(history);
        
        return history;
      } else {
        debugPrint('ApiService: Error al obtener historial - código ${response.statusCode}');
        // Si falla la API, intentamos recuperar datos locales
        return _getLocalMedicationHistory();
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en getMedicationHistory: $error');
      // En caso de error, intentamos recuperar datos locales
      return _getLocalMedicationHistory();
    }
  }
  
  // Obtener historial desde almacenamiento local
  Future<List<MedicationHistory>> _getLocalMedicationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('medication_history');
      
      if (historyJson != null) {
        final List<dynamic> data = json.decode(historyJson);
        debugPrint('ApiService: Recuperados ${data.length} registros de historial local');
        return data.map((item) => MedicationHistory.fromJson(item)).toList();
      }
      
      return [];
    } catch (error) {
      debugPrint('ApiService: Error al obtener historial local: $error');
      return [];
    }
  }
  
  // Guardar historial en almacenamiento local
  Future<void> _saveLocalMedicationHistory(List<MedicationHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(history.map((h) => h.toJson()).toList());
      await prefs.setString('medication_history', historyJson);
      debugPrint('ApiService: Historial guardado localmente (${history.length} registros)');
    } catch (e) {
      debugPrint('ApiService: Error al guardar historial local: $e');
    }
  }
  
  // Método para guardar historial de medicamentos
  Future<bool> saveMedicationHistory(MedicationHistory history) async {
    try {
      debugPrint('ApiService: Guardando registro de historial para medicamento: ${history.medicationId}');
      
      // Convertir a JSON
      final historyJson = history.toJson();
      
      // Añadir userId si no está presente
      if (!historyJson.containsKey('userId')) {
        historyJson['userId'] = userId;
      }
      
      debugPrint('ApiService: JSON para enviar: ${jsonEncode(historyJson)}');
      
      // Primero guardar localmente
      await _saveLocalHistoryRecord(history);
      
      // Luego intentar llamar a la API
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/SaveMedicationHistory'),
          headers: _headers,
          body: json.encode(historyJson),
        ).timeout(const Duration(seconds: 20));
        
        debugPrint('ApiService: Respuesta de SaveMedicationHistory - Status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          debugPrint('ApiService: Registro guardado con éxito en la API');
          return true;
        } else {
          debugPrint('ApiService: Error al guardar en API: ${response.statusCode} - ${response.body}');
          return true; // Consideramos exitoso si se guardó localmente
        }
      } catch (apiError) {
        debugPrint('ApiService: Error al guardar en API: $apiError');
        return true; // Consideramos exitoso si se guardó localmente
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en saveMedicationHistory: $error');
      return false;
    }
  }
  
  // Guardar historial en almacenamiento local (un solo registro)
  Future<void> _saveLocalHistoryRecord(MedicationHistory history) async {
    try {
      // Obtener historial actual
      final currentHistory = await _getLocalMedicationHistory();
      
      // Añadir nuevo registro
      currentHistory.add(history);
      
      // Guardar en SharedPreferences
      await _saveLocalMedicationHistory(currentHistory);
      
      debugPrint('ApiService: Registro de historial guardado localmente');
    } catch (error) {
      debugPrint('ApiService: Error al guardar historial local: $error');
    }
  }
  
  // Método para obtener patrones de medicamentos
  Future<Map<String, dynamic>> analyzeMedicationPatterns(String medicationId) async {
    try {
      debugPrint('ApiService: Analizando patrones para medicamento: $medicationId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/AnalyzeMedicationPatterns?userId=$userId&medicationId=$medicationId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('ApiService: Respuesta de AnalyzeMedicationPatterns - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('ApiService: Patrones obtenidos: ${data['hasPatterns']}');
        return data;
      } else {
        debugPrint('ApiService: Error al obtener patrones: ${response.statusCode}');
        return {
          'hasPatterns': false,
          'patterns': [],
          'adherence': 0,
        };
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en analyzeMedicationPatterns: $error');
      return {
        'hasPatterns': false,
        'patterns': [],
        'adherence': 0,
      };
    }
  }
  
  // Método para obtener sugerencia de tiempo óptimo
  Future<Map<String, dynamic>> suggestOptimalTime(String medicationId) async {
    try {
      debugPrint('ApiService: Obteniendo sugerencia de tiempo óptimo para: $medicationId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/SuggestOptimalTime?userId=$userId&medicationId=$medicationId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('ApiService: Respuesta de SuggestOptimalTime - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('ApiService: Error al obtener sugerencia: ${response.statusCode}');
        return {
          'suggestedHour': null,
          'suggestedMinute': null,
          'explanation': 'No se pudo obtener una sugerencia en este momento.',
          'confidence': 0,
          'isSignificantChange': false,
        };
      }
    } catch (error) {
      debugPrint('ApiService: Excepción en suggestOptimalTime: $error');
      return {
        'suggestedHour': null,
        'suggestedMinute': null,
        'explanation': 'Error al obtener sugerencia: $error',
        'confidence': 0,
        'isSignificantChange': false,
      };
    }
  }
  
  // Método privado para convertir respuesta JSON a objetos Medication
  List<Medication> _convertToMedications(List<dynamic> data) {
    final List<Medication> medications = [];
    
    for (var item in data) {
      try {
        // Extraer datos del JSON
        final id = item['id'] ?? '';
        final name = item['name'] ?? '';
        final dosage = item['dosage'] ?? '';
        
        // Convertir formato de hora basado en los datos disponibles
        TimeOfDay scheduledTime;
        if (item.containsKey('timeHour') && item.containsKey('timeMinute')) {
          scheduledTime = TimeOfDay(
            hour: item['timeHour'] ?? 8,
            minute: item['timeMinute'] ?? 0,
          );
        } else if (item.containsKey('scheduledTimeHour') && item.containsKey('scheduledTimeMinute')) {
          scheduledTime = TimeOfDay(
            hour: item['scheduledTimeHour'] ?? 8,
            minute: item['scheduledTimeMinute'] ?? 0,
          );
        } else {
          // Valor predeterminado si no hay datos de hora
          scheduledTime = const TimeOfDay(hour: 8, minute: 0);
        }
        
        // Obtener los días de la semana
        List<bool> weekDays;
        if (item.containsKey('weekDays') && item['weekDays'] is List) {
          weekDays = (item['weekDays'] as List).map<bool>((day) => day as bool).toList();
        } else if (item.containsKey('daysOfWeek') && item['daysOfWeek'] is String) {
          // Formato alternativo: días como string separado por comas (L,M,X,J,V,S,D)
          final daysString = item['daysOfWeek'] as String;
          weekDays = [
            daysString.contains('L'),
            daysString.contains('M'),
            daysString.contains('X'),
            daysString.contains('J'),
            daysString.contains('V'),
            daysString.contains('S'),
            daysString.contains('D'),
          ];
        } else {
          // Valor predeterminado: todos los días
          weekDays = List.filled(7, true);
        }
        
        // Otros campos
        final instructions = item['instructions'] ?? '';
        final importance = item['importance'] ?? 3;
        final category = item['category'];
        final treatmentDuration = item['treatmentDuration'];
        final sideEffects = item['sideEffects'];
        final reminderStrategy = item['reminderStrategy'] ?? 'standard';
        
        // Fechas
        final createdAt = item.containsKey('createdAt') && item['createdAt'] != null
            ? DateTime.parse(item['createdAt'])
            : DateTime.now();
            
        final updatedAt = item.containsKey('updatedAt') && item['updatedAt'] != null
            ? DateTime.parse(item['updatedAt'])
            : null;
        
        // Crear el objeto Medication
        medications.add(Medication(
          id: id,
          name: name,
          dosage: dosage,
          scheduledTime: scheduledTime,
          weekDays: weekDays,
          instructions: instructions,
          importance: importance,
          category: category,
          treatmentDuration: treatmentDuration,
          sideEffects: sideEffects,
          reminderStrategy: reminderStrategy,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ));
      } catch (e) {
        debugPrint('ApiService: Error al convertir medicamento: $e');
        // Continuar con el siguiente item si hay error
      }
    }
    
    return medications;
  }
  
  // Método privado para convertir objeto Medication a JSON
  Map<String, dynamic> _convertMedicationToJson(Medication medication) {
    // Convertir días de la semana a formato de string (si necesario)
    final List<String> dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    List<String> selectedDays = [];
    
    for (int i = 0; i < medication.weekDays.length; i++) {
      if (medication.weekDays[i]) {
        selectedDays.add(dayLetters[i]);
      }
    }
    
    final String daysOfWeek = selectedDays.join(',');
    
    return {
      'id': medication.id,
      'userId': userId,
      'name': medication.name,
      'dosage': medication.dosage,
      'timeHour': medication.scheduledTime.hour,
      'timeMinute': medication.scheduledTime.minute,
      'daysOfWeek': daysOfWeek,
      'instructions': medication.instructions,
      'importance': medication.importance,
      'category': medication.category,
      'treatmentDuration': medication.treatmentDuration,
      'sideEffects': medication.sideEffects,
      'reminderStrategy': medication.reminderStrategy,
    };
  }
  
  // Método de diagnóstico para verificar la conexión a la API
  Future<Map<String, dynamic>> diagnosisApiConnection() async {
    final result = <String, dynamic>{};
    
    try {
      // Comprobar conexión a internet
      final internetCheck = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      result['internetConnected'] = internetCheck.statusCode == 200;
    } catch (e) {
      result['internetConnected'] = false;
      result['internetError'] = e.toString();
    }
    
    try {
      // Comprobar conexión a la API
      final response = await http.get(
        Uri.parse('$baseUrl/GetMedicaments?userId=test_connection'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      result['apiConnected'] = true;
      result['apiStatusCode'] = response.statusCode;
      result['apiResponse'] = response.statusCode == 200 
          ? 'Conexión exitosa' 
          : 'Código de estado: ${response.statusCode}';
    } catch (e) {
      result['apiConnected'] = false;
      result['apiError'] = e.toString();
    }
    
    // Verificar con otra función para descartar problemas específicos
    try {
      final testData = {'name': 'Test User', 'email': 'test@example.com'};
      final response = await http.post(
        Uri.parse('$baseUrl/RegisterUser'),
        headers: _headers,
        body: json.encode(testData),
      ).timeout(const Duration(seconds: 10));
      
      result['registerUserConnected'] = true;
      result['registerUserStatusCode'] = response.statusCode;
    } catch (e) {
      result['registerUserConnected'] = false;
      result['registerUserError'] = e.toString();
    }
    
    return result;
  }
}