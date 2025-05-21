// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  
  // URL base y clave de función (tus datos reales)
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
  bool get isAuthenticated => _userId != null && _userId!.isNotEmpty;
  
  // Getters para los datos del usuario
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  
  // Encabezados HTTP con autenticación
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-functions-key': functionKey,
    'Accept': 'application/json',
  };
  
  // Método mejorado para diagnosticar la conexión a la API
  Future<Map<String, dynamic>> diagnoseApiConnection() async {
    final result = <String, dynamic>{};
    
    debugPrint('AuthService: Iniciando diagnóstico completo...');
    
    // 1. Comprobar conexión a internet
    try {
      debugPrint('AuthService: Verificando conexión a Internet...');
      final internetCheck = await http.get(
        Uri.parse('https://www.google.com'),
        headers: {'User-Agent': 'PastilleroApp/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      result['internetConnected'] = internetCheck.statusCode >= 200 && internetCheck.statusCode < 300;
      result['internetStatusCode'] = internetCheck.statusCode;
      debugPrint('AuthService: Internet check - Status: ${internetCheck.statusCode}');
    } catch (e) {
      result['internetConnected'] = false;
      result['internetError'] = e.toString();
      debugPrint('AuthService: Error de Internet - $e');
    }
    
    // 2. Verificar acceso básico a Azure Functions
    try {
      debugPrint('AuthService: Verificando acceso básico a Azure Functions...');
      final basicCheckUrl = Uri.parse('$baseUrl/GetMedicaments');
      
      final basicResponse = await http.get(
        basicCheckUrl.replace(queryParameters: {'userId': 'test_connection'}),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));
      
      result['azureFunctionsAccessible'] = true;
      result['azureFunctionsStatusCode'] = basicResponse.statusCode;
      debugPrint('AuthService: Azure Functions accessible - Status: ${basicResponse.statusCode}');
    } catch (e) {
      result['azureFunctionsAccessible'] = false;
      result['azureFunctionsError'] = e.toString();
      debugPrint('AuthService: Error de acceso a Azure Functions - $e');
    }
    
    // 3. Probar específicamente el endpoint RegisterUser
    try {
      debugPrint('AuthService: Probando endpoint RegisterUser...');
      final registerUrl = Uri.parse('$baseUrl/RegisterUser');
      result['registerUserUrl'] = registerUrl.toString();
      
      final testData = {
        'name': 'Test User Diagnostic',
        'email': 'test-diagnostic@example.com'
      };
      
      debugPrint('AuthService: Enviando datos de prueba: ${jsonEncode(testData)}');
      debugPrint('AuthService: Headers: $_headers');
      
      final response = await http.post(
        registerUrl,
        headers: _headers,
        body: jsonEncode(testData),
      ).timeout(const Duration(seconds: 20));
      
      result['registerUserConnected'] = response.statusCode >= 200 && response.statusCode < 300;
      result['registerUserStatusCode'] = response.statusCode;
      result['registerUserResponse'] = response.body;
      
      debugPrint('AuthService: RegisterUser response - Status: ${response.statusCode}');
      debugPrint('AuthService: RegisterUser body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        result['apiAccessible'] = true;
        result['message'] = 'Conexión exitosa a la API';
      } else {
        result['apiAccessible'] = false;
        result['apiError'] = 'Error HTTP ${response.statusCode}';
        
        // Analizar errores específicos
        if (response.statusCode == 500) {
          if (response.body.contains('SqlConnectionString') || 
              response.body.contains('cadena de conexión')) {
            result['specificError'] = 'Error de configuración de base de datos en Azure Functions';
            result['suggestion'] = 'Verificar configuración de SqlConnectionString en Azure';
          } else {
            result['specificError'] = 'Error interno del servidor';
            result['suggestion'] = 'Revisar logs de Azure Functions para más detalles';
          }
        } else if (response.statusCode == 401) {
          result['specificError'] = 'Error de autenticación';
          result['suggestion'] = 'Verificar la function key';
        } else if (response.statusCode == 404) {
          result['specificError'] = 'Endpoint no encontrado';
          result['suggestion'] = 'Verificar que la Azure Function esté desplegada correctamente';
        }
      }
    } catch (e) {
      result['registerUserConnected'] = false;
      result['registerUserError'] = e.toString();
      result['apiAccessible'] = false;
      debugPrint('AuthService: Error en RegisterUser - $e');
      
      if (e.toString().contains('TimeoutException')) {
        result['specificError'] = 'Timeout de conexión';
        result['suggestion'] = 'La API está tardando mucho en responder';
      } else if (e.toString().contains('SocketException')) {
        result['specificError'] = 'Error de red';
        result['suggestion'] = 'Verificar conectividad de red';
      }
    }
    
    // 4. Información adicional para debugging
    result['timestamp'] = DateTime.now().toIso8601String();
    result['baseUrl'] = baseUrl;
    result['hasValidFunctionKey'] = functionKey.isNotEmpty;
    
    debugPrint('AuthService: Diagnóstico completo: $result');
    return result;
  }
  
  // Registro/creación de usuario con llamada a la API mejorada
  Future<bool> registerUser({String? name, String? email}) async {
    try {
      debugPrint('AuthService: === INICIANDO REGISTRO DE USUARIO ===');
      debugPrint('AuthService: Nombre: $name, Email: $email');
      
      // Preparar datos para enviar
      final userData = {
        'name': name ?? 'Usuario',
        'email': email?.isNotEmpty == true ? email : null,
      };
      
      // Solo incluir ID si ya existe uno
      if (_userId != null && _userId!.isNotEmpty) {
        userData['id'] = _userId;
      }
      
      debugPrint('AuthService: Datos a enviar: ${jsonEncode(userData)}');
      debugPrint('AuthService: URL: $baseUrl/RegisterUser');
      debugPrint('AuthService: Headers: $_headers');
      
      final response = await http.post(
        Uri.parse('$baseUrl/RegisterUser'),
        headers: _headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 20));
      
      debugPrint('AuthService: === RESPUESTA DEL SERVIDOR ===');
      debugPrint('AuthService: Status Code: ${response.statusCode}');
      debugPrint('AuthService: Response Body: ${response.body}');
      debugPrint('AuthService: Response Headers: ${response.headers}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Procesar respuesta exitosa
        try {
          final responseData = jsonDecode(response.body);
          debugPrint('AuthService: Datos decodificados: $responseData');
          
          // Extraer ID del usuario (puede venir como 'id' o 'Id')
          final newUserId = responseData['id'] ?? responseData['Id'] ?? responseData['ID'];
          
          if (newUserId != null) {
            _userId = newUserId.toString();
            _userName = name ?? 'Usuario';
            _userEmail = email;
            
            // Guardar localmente
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_userIdKey, _userId!);
            
            if (name != null && name.isNotEmpty) {
              await prefs.setString(_userNameKey, name);
            }
            
            if (email != null && email.isNotEmpty) {
              await prefs.setString(_userEmailKey, email);
            }
            
            debugPrint('AuthService: ✅ Usuario registrado exitosamente');
            debugPrint('AuthService: ID asignado: $_userId');
            return true;
          } else {
            debugPrint('AuthService: ⚠️ Respuesta exitosa pero sin ID de usuario');
            // Intentar usar respuesta como ID directo si es string
            if (responseData is String) {
              _userId = responseData;
            } else {
              // Generar ID local como fallback
              _userId = 'USR_${DateTime.now().millisecondsSinceEpoch}';
            }
            
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
            
            debugPrint('AuthService: ✅ Usuario registrado con ID generado: $_userId');
            return true;
          }
        } catch (jsonError) {
          debugPrint('AuthService: Error al procesar JSON: $jsonError');
          // Si hay error en JSON pero la respuesta fue exitosa, usar datos locales
          return await _createLocalUser(name, email);
        }
      } else {
        // Manejar errores HTTP específicos
        debugPrint('AuthService: ❌ Error HTTP ${response.statusCode}');
        
        String errorMessage = 'Error desconocido';
        
        try {
          final errorBody = response.body;
          if (errorBody.isNotEmpty) {
            // Intentar parsear como JSON primero
            try {
              final errorJson = jsonDecode(errorBody);
              errorMessage = errorJson['message'] ?? errorJson['error'] ?? errorBody;
            } catch (_) {
              // Si no es JSON válido, usar el texto tal como está
              errorMessage = errorBody;
            }
          }
          
          debugPrint('AuthService: Mensaje de error: $errorMessage');
          
          if (response.statusCode == 500) {
            if (errorMessage.contains('SqlConnectionString') || 
                errorMessage.contains('cadena de conexión')) {
              debugPrint('AuthService: 🔧 Error de configuración de BD detectado');
              // Para desarrollo, crear usuario local
              return await _createLocalUser(name, email);
            }
          }
        } catch (e) {
          debugPrint('AuthService: Error al procesar error response: $e');
        }
        
        // Para cualquier error de servidor, intentar crear usuario local
        return await _createLocalUser(name, email);
      }
    } catch (e) {
      debugPrint('AuthService: ❌ Excepción durante registro: $e');
      
      if (e.toString().contains('TimeoutException')) {
        debugPrint('AuthService: Timeout - creando usuario local');
      } else if (e.toString().contains('SocketException')) {
        debugPrint('AuthService: Error de red - creando usuario local');
      }
      
      // En caso de cualquier error, crear usuario local
      return await _createLocalUser(name, email);
    }
  }
  
  // Crear usuario local como fallback
  Future<bool> _createLocalUser(String? name, String? email) async {
    try {
      debugPrint('AuthService: 📱 Creando usuario local como fallback');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Generar ID único local
      _userId = 'LOCAL_${DateTime.now().millisecondsSinceEpoch}';
      _userName = name ?? 'Usuario';
      _userEmail = email;
      
      // Guardar en SharedPreferences
      await prefs.setString(_userIdKey, _userId!);
      
      if (name != null && name.isNotEmpty) {
        await prefs.setString(_userNameKey, name);
      }
      
      if (email != null && email.isNotEmpty) {
        await prefs.setString(_userEmailKey, email);
      }
      
      debugPrint('AuthService: ✅ Usuario local creado exitosamente');
      debugPrint('AuthService: ID local: $_userId');
      debugPrint('AuthService: Nombre: $_userName');
      
      return true;
    } catch (e) {
      debugPrint('AuthService: ❌ Error al crear usuario local: $e');
      return false;
    }
  }
  
  // Método para intentar sincronizar usuario local con servidor
  Future<bool> syncLocalUserWithServer() async {
    if (_userId == null || !_userId!.startsWith('LOCAL_')) {
      return true; // Ya está sincronizado o no es usuario local
    }
    
    try {
      debugPrint('AuthService: 🔄 Intentando sincronizar usuario local con servidor');
      
      final userData = {
        'name': _userName ?? 'Usuario',
        'email': _userEmail,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/RegisterUser'),
        headers: _headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        final serverId = responseData['id'] ?? responseData['Id'] ?? responseData['ID'];
        
        if (serverId != null) {
          // Actualizar con ID del servidor
          final oldLocalId = _userId;
          _userId = serverId.toString();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userIdKey, _userId!);
          
          debugPrint('AuthService: ✅ Usuario sincronizado: $oldLocalId -> $_userId');
          return true;
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error durante sincronización: $e');
    }
    
    return false;
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
      
      debugPrint('AuthService: ✅ Sesión cerrada con éxito');
      return true;
    } catch (e) {
      debugPrint('AuthService: ❌ Error al cerrar sesión: $e');
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
      debugPrint('AuthService: 🔄 Actualizando información de usuario');
      
      // Intentar actualizar en la API si no es usuario local
      if (!_userId!.startsWith('LOCAL_')) {
        final userData = {
          'id': _userId,
          'name': name ?? _userName,
          'email': email ?? _userEmail
        };
        
        try {
          final response = await http.post(
            Uri.parse('$baseUrl/RegisterUser'),
            headers: _headers,
            body: jsonEncode(userData),
          ).timeout(const Duration(seconds: 15));
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint('AuthService: ✅ Usuario actualizado en servidor');
          } else {
            debugPrint('AuthService: ⚠️ Error al actualizar en servidor: ${response.statusCode}');
          }
        } catch (apiError) {
          debugPrint('AuthService: ⚠️ Error de API al actualizar: $apiError');
        }
      }
      
      // Actualizar localmente siempre
      final prefs = await SharedPreferences.getInstance();
      
      if (name != null && name.isNotEmpty) {
        _userName = name;
        await prefs.setString(_userNameKey, name);
      }
      
      if (email != null) {
        _userEmail = email;
        if (email.isNotEmpty) {
          await prefs.setString(_userEmailKey, email);
        } else {
          await prefs.remove(_userEmailKey);
        }
      }
      
      debugPrint('AuthService: ✅ Información actualizada localmente');
      return true;
    } catch (e) {
      debugPrint('AuthService: ❌ Error al actualizar información: $e');
      return false;
    }
  }
  
  // Método para verificar si hay conexión a la API
  Future<bool> isApiAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/GetMedicaments').replace(
          queryParameters: {'userId': 'test_ping'}
        ),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode != 500; // Cualquier cosa menos error interno del servidor
    } catch (e) {
      return false;
    }
  }
  
  // Método para obtener estado detallado del usuario
  Map<String, dynamic> getUserStatus() {
    return {
      'isAuthenticated': isAuthenticated,
      'userId': _userId,
      'userName': _userName,
      'userEmail': _userEmail,
      'isLocalUser': _userId?.startsWith('LOCAL_') == true,
      'needsSync': _userId?.startsWith('LOCAL_') == true,
    };
  }
}