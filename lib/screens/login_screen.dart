// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthService();
      
      // Diagnóstico de conexión previo al registro
      final diagnostics = await authService.diagnoseApiConnection();
      debugPrint('Diagnóstico de conexión: $diagnostics');
      
      if (diagnostics['internetConnected'] == false) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No hay conexión a Internet. Verifica tu conexión e intenta nuevamente.";
        });
        return;
      }
      
      final success = await authService.registerUser(
        name: _nameController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
      );

      if (success) {
        // Navegar a la pantalla principal
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // Mostrar error
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Error al registrar usuario. Intenta nuevamente.";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo o ícono
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FontAwesomeIcons.pills,
                    size: 60,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Título
              const Text(
                'PASTILLERO INTELIGENTE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Subtítulo
              Text(
                'Configura tu perfil para comenzar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Mensaje de error (si existe)
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(FontAwesomeIcons.circleExclamation, 
                           size: 16, color: Colors.red.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Formulario
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Campo de nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(FontAwesomeIcons.user, size: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campo de email (opcional)
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email (opcional)',
                        helperText: 'Recomendado para recuperación de cuenta',
                        prefixIcon: Icon(FontAwesomeIcons.envelope, size: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón de registro
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('CONECTANDO...'),
                          ],
                        )
                      : const Text(
                          'COMENZAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón para diagnóstico de conexión
              TextButton.icon(
                onPressed: _isLoading ? null : _showConnectionDiagnostics,
                icon: Icon(FontAwesomeIcons.wifi, size: 16),
                label: Text('Diagnosticar conexión'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nota de privacidad
              Text(
                'Tus datos se almacenan localmente en tu dispositivo y son utilizados únicamente para mejorar tu experiencia con la aplicación.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showConnectionDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = AuthService();
      final diagnostics = await authService.diagnoseApiConnection();
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      // Mostrar los resultados del diagnóstico
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(FontAwesomeIcons.wifi, size: 18, color: Colors.blue),
              SizedBox(width: 10),
              Text('Diagnóstico de conexión'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDiagnosticRow(
                  'Conexión a Internet',
                  diagnostics['internetConnected'] == true,
                  details: diagnostics['internetError'],
                ),
                SizedBox(height: 10),
                _buildDiagnosticRow(
                  'Conexión a API',
                  diagnostics['apiConnected'] == true,
                  details: diagnostics['apiError'],
                ),
                if (diagnostics['apiConnected'] == true) ...[
                  SizedBox(height: 10),
                  _buildDiagnosticRow(
                    'Respuesta de API',
                    diagnostics['apiStatusCode'] >= 200 && 
                    diagnostics['apiStatusCode'] < 300,
                    details: 'Código: ${diagnostics['apiStatusCode']}',
                  ),
                ],
                SizedBox(height: 10),
                _buildDiagnosticRow(
                  'Registro de usuario',
                  diagnostics['registerUserConnected'] == true,
                  details: diagnostics['registerUserError'],
                ),
                SizedBox(height: 20),
                Text(
                  'Diagnóstico completo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  diagnostics.toString(),
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error durante el diagnóstico: $e";
      });
    }
  }
  
  Widget _buildDiagnosticRow(String label, bool isSuccess, {String? details}) {
    return Row(
      children: [
        Icon(
          isSuccess ? FontAwesomeIcons.circleCheck : FontAwesomeIcons.circleXmark,
          size: 16,
          color: isSuccess ? Colors.green : Colors.red,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (details != null && !isSuccess)
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}