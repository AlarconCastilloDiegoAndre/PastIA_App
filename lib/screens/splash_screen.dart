// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Pequeña pausa para mostrar la pantalla de splash
    await Future.delayed(const Duration(seconds: 2));
    
    final authService = AuthService();
    await authService.initialize();
    
    if (mounted) {
      if (authService.isAuthenticated) {
        // Usuario ya autenticado, ir a pantalla principal
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Usuario no autenticado, ir a pantalla de login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono o logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const FaIcon(
                FontAwesomeIcons.pills,
                size: 64,
                color: Colors.blue,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Nombre de la aplicación
            const Text(
              'PASTILLERO INTELIGENTE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Subtítulo o eslogan
            Text(
              'Tu asistente de medicamentos personal',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            
            const SizedBox(height: 48),
            
            // Indicador de carga
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}