// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  
  // URL base y clave de función (actualizada con tus datos)
  final String baseUrl = '...';
  final String functionKey = '...';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  String? _userId;
  String? _userName;
  String? _userEmail;
  
  // Inicializar el servicio de autenticación
  Future<void> initialize() async {
    await loadUserData();
  }
  
  // Cargar datos del usuario desde almacenamiento local
  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString(_userIdKey);
      _userName = prefs.getString(_userNameKey);
      _userEmail = prefs.getString(_userEmailKey);
      
      debugPrint('AuthService: Datos cargados - UserId: $_userId, UserName: $_userName');
    } catch (e) {
      debugPrint('Error al cargar datos de usuario: $e');
      // En caso de error, aseguramos que los valores son nulos
      _userId = null;
      _userName = null;
      _userEmail = null;
    }
  }
  
  // Verificar si el usuario está autenticado
  bool get isAuthenticated => _userId != null;
  
  // Getters para los datos del usuario
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  
  // Encabezados HTTP con autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-functions-key': functionKey
  };
  
  // Método para diagnosticar la conexión a la API
  Future<Map<String, dynamic>> diagnoseApiConnection() async {
    final result = <String, dynamic>{};
    
    try {
      // Comprobar conexión a internet
      final internetCheck = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      result['internetConnected'] = internetCheck.statusCode >= 200 && internetCheck.statusCode < 300;
      result['internetStatusCode'] = internetCheck.statusCode;
    } catch (e) {
      result['internetConnected'] = false;
      result['internetError'] = e.toString();
    }
    
    try {
      // Comprobar conexión a la API
      final apiUrl = Uri.parse('$baseUrl/RegisterUser');
      result['apiUrl'] = apiUrl.toString();
      
      final testData = {
        'name': 'Test User',
        'email': 'test@example.com'
      };
      
      final response = await http.post(
        apiUrl,
        headers: _headers,
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 10));
      
      result['apiConnected'] = true;
      result['apiStatusCode'] = response.statusCode;
      result['apiResponse'] = response.body;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        result['apiAccessible'] = true;
      } else {
        result['apiAccessible'] = false;
        result['apiError'] = 'Código de estado incorrecto: ${response.statusCode}';
      }
    } catch (e) {
      result['apiConnected'] = false;
      result['apiError'] = e.toString();
    }
    
    return result;
  }
  
  // Registro/creación de usuario con llamada a la API
  Future<bool> registerUser({String? name, String? email}) async {
    try {
      debugPrint('AuthService: Intentando registrar usuario - $name, $email');
      
      // Primero intentar llamar a la API
      final userData = {
        'id': _userId, // Enviar ID si ya existe
        'name': name ?? 'Usuario',
        'email': email
      };
      
      debugPrint('AuthService: Datos a enviar - ${jsonEncode(userData)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/RegisterUser'),
        headers: _headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));
      
      debugPrint('AuthService: Respuesta del servidor - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Procesar respuesta exitosa
        final responseData = jsonDecode(response.body);
        _userId = responseData['id'];
        _userName = name ?? 'Usuario';
        _userEmail = email;
        
        // Guardar localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userIdKey, _userId!);
        
        if (name != null) {
          await prefs.setString(_userNameKey, name);
        }
        
        if (email != null && email.isNotEmpty) {
          await prefs.setString(_userEmailKey, email);
        }
        
        debugPrint('AuthService: Usuario registrado con éxito - ID: $_userId');
        return true;
      } else {
        debugPrint('AuthService: Error en API RegisterUser - ${response.statusCode} - ${response.body}');
        
        // Si la API falla, intentemos con un usuario predeterminado
        return _useDefaultUser(name, email);
      }
    } catch (e) {
      debugPrint('AuthService: Error al registrar usuario en API - $e');
      
      // Si hay error de conexión, usar un usuario predeterminado
      return _useDefaultUser(name, email);
    }
  }
  
  // Usar un usuario predeterminado como fallback
  Future<bool> _useDefaultUser(String? name, String? email) async {
    try {
      debugPrint('AuthService: Usando usuario predeterminado como fallback');
      final prefs = await SharedPreferences.getInstance();
      
      // Generar un ID local si no existe
      if (_userId == null) {
        _userId = 'LOCAL_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      _userName = name ?? 'Usuario';
      _userEmail = email;
      
      // Guardar en SharedPreferences
      await prefs.setString(_userIdKey, _userId!);
      
      if (name != null) {
        await prefs.setString(_userNameKey, name);
      }
      
      if (email != null && email.isNotEmpty) {
        await prefs.setString(_userEmailKey, email);
      }
      
      debugPrint('AuthService: Usando usuario predeterminado - ID: $_userId');
      return true;
    } catch (e) {
      debugPrint('AuthService: Error al usar usuario predeterminado - $e');
      return false;
    }
  }
  
  // Cerrar sesión
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNameKey);
      await prefs.remove(_userEmailKey);
      
      _userId = null;
      _userName = null;
      _userEmail = null;
      
      debugPrint('AuthService: Sesión cerrada con éxito');
      return true;
    } catch (e) {
      debugPrint('AuthService: Error al cerrar sesión - $e');
      return false;
    }
  }
  
  // Método para actualizar información del usuario
  Future<bool> updateUserInfo({String? name, String? email}) async {
    if (_userId == null) {
      debugPrint('AuthService: No se puede actualizar - usuario no autenticado');
      return false;
    }
    
    try {
      debugPrint('AuthService: Intentando actualizar información de usuario');
      
      // Intentar actualizar en la API
      final userData = {
        'id': _userId,
        'name': name ?? _userName,
        'email': email ?? _userEmail
      };
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/RegisterUser'), // Usamos la misma función para actualizar
          headers: _headers,
          body: jsonEncode(userData),
        ).timeout(const Duration(seconds: 15));
        
        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint('AuthService: Error al actualizar usuario en API - ${response.statusCode}');
        } else {
          debugPrint('AuthService: Usuario actualizado con éxito en la API');
        }
      } catch (apiError) {
        debugPrint('AuthService: Error al llamar API para actualizar usuario - $apiError');
      }
      
      // Actualizar localmente independientemente de la API
      final prefs = await SharedPreferences.getInstance();
      
      if (name != null) {
        _userName = name;
        await prefs.setString(_userNameKey, name);
      }
      
      if (email != null) {
        _userEmail = email;
        await prefs.setString(_userEmailKey, email);
      }
      
      debugPrint('AuthService: Información actualizada localmente');
      return true;
    } catch (e) {
      debugPrint('AuthService: Error al actualizar información del usuario - $e');
      return false;
    }
  }
}