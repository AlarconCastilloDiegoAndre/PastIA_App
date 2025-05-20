// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// Pantallas
import 'package:pastillero_inteligente/screens/home_screen.dart';
import 'package:pastillero_inteligente/screens/login_screen.dart';
import 'package:pastillero_inteligente/screens/splash_screen.dart';
import 'package:pastillero_inteligente/screens/connection_diagnostic_screen.dart';

// Proveedores
import 'package:pastillero_inteligente/providers/medication_provider.dart';

// Servicios
import 'package:pastillero_inteligente/services/auth_service.dart';
import 'package:pastillero_inteligente/services/api_service.dart';
import 'package:pastillero_inteligente/services/ml_service.dart';

void main() async {
  // Asegurar que la inicialización de Flutter se complete
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientación preferida
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Pre-inicializar servicios críticos para mejor rendimiento
  final authService = AuthService();
  await authService.initialize();
  
  // Pre-cargar modelo de ML si es posible
  final mlService = MLService();
  await mlService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
      ],
      child: MaterialApp(
        title: 'Pastillero Inteligente',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF2196F3), // Color azul de la app
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            color: Color(0xFF2196F3),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2196F3),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/diagnostics': (context) => const ConnectionDiagnosticScreen(),
        },
        // Manejo de rutas desconocidas
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (ctx) => const SplashScreen(),
          );
        },
        // Desactivar banner de depuración
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Clase para gestionar el estado global de la conexión (opcional, para futuras mejoras)
class ConnectionStatus with ChangeNotifier {
  bool _isConnected = true;
  DateTime? _lastSyncTime;
  
  bool get isConnected => _isConnected;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  void setConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      notifyListeners();
    }
  }
  
  void updateSyncTime() {
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }
  
  // Método para verificar periódicamente la conexión (podría usarse en futuras versiones)
  Future<void> checkConnection() async {
    try {
      final apiService = ApiService();
      final diagnostics = await apiService.diagnosisApiConnection();
      setConnected(diagnostics['apiConnected'] == true);
      
      if (_isConnected) {
        updateSyncTime();
      }
    } catch (e) {
      setConnected(false);
    }
  }
}