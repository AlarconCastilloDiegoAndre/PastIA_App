// lib/screens/connection_diagnostic_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';
import 'package:pastillero_inteligente/services/api_service.dart';

class ConnectionDiagnosticScreen extends StatefulWidget {
  const ConnectionDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<ConnectionDiagnosticScreen> createState() => _ConnectionDiagnosticScreenState();
}

class _ConnectionDiagnosticScreenState extends State<ConnectionDiagnosticScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _authDiagnostics = {};
  Map<String, dynamic> _apiDiagnostics = {};
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }
  
  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Ejecutar diagnósticos
      final authService = AuthService();
      final apiService = ApiService();
      
      // Ejecutar en paralelo
      final authDiagnosticsFuture = authService.diagnoseApiConnection();
      final apiDiagnosticsFuture = apiService.diagnosisApiConnection();
      
      // Esperar resultados
      final results = await Future.wait([
        authDiagnosticsFuture,
        apiDiagnosticsFuture,
      ]);
      
      setState(() {
        _authDiagnostics = results[0];
        _apiDiagnostics = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error durante el diagnóstico: $e";
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(FontAwesomeIcons.networkWired, size: 16),
            SizedBox(width: 8),
            Text('Diagnóstico de Conexión'),
          ],
        ),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDiagnosticResults(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _runDiagnostics,
          icon: Icon(FontAwesomeIcons.arrowsRotate, size: 16),
          label: Text('Volver a ejecutar diagnóstico'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Ejecutando diagnóstico de conexión...',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Esto puede tomar unos segundos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.circleExclamation,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'Error al ejecutar diagnóstico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _errorMessage ?? 'Ocurrió un error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDiagnosticResults() {
    // Determinar estado general
    final bool internetConnected = _authDiagnostics['internetConnected'] == true || 
                                 _apiDiagnostics['internetConnected'] == true;
                                 
    final bool apiConnected = _authDiagnostics['apiConnected'] == true ||
                           _apiDiagnostics['apiConnected'] == true;
                           
    final String overallStatus = internetConnected && apiConnected 
        ? 'Conexión exitosa'
        : internetConnected && !apiConnected
            ? 'Conectado a Internet, pero no a la API'
            : !internetConnected
                ? 'Sin conexión a Internet'
                : 'Estado desconocido';
    
    final Color statusColor = internetConnected && apiConnected
        ? Colors.green
        : internetConnected && !apiConnected
            ? Colors.orange
            : Colors.red;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado general
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  internetConnected && apiConnected
                      ? FontAwesomeIcons.circleCheck
                      : internetConnected && !apiConnected
                          ? FontAwesomeIcons.circleExclamation
                          : FontAwesomeIcons.circleXmark,
                  color: statusColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de conexión',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        overallStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Sección: Internet
          _buildDiagnosticSection(
            title: 'Conexión a Internet',
            isSuccess: internetConnected,
            items: [
              {
                'label': 'Estado',
                'value': internetConnected ? 'Conectado' : 'Sin conexión',
                'isSuccess': internetConnected,
              },
              if (!internetConnected && (_authDiagnostics['internetError'] != null || _apiDiagnostics['internetError'] != null))
                {
                  'label': 'Error',
                  'value': _authDiagnostics['internetError'] ?? _apiDiagnostics['internetError'],
                  'isSuccess': false,
                },
            ],
          ),
          
          SizedBox(height: 16),
          
          // Sección: API
          _buildDiagnosticSection(
            title: 'Conexión a API',
            isSuccess: apiConnected,
            items: [
              {
                'label': 'Estado',
                'value': apiConnected ? 'Conectado' : 'Sin conexión',
                'isSuccess': apiConnected,
              },
              if (apiConnected)
                {
                  'label': 'Código de respuesta',
                  'value': _authDiagnostics['apiStatusCode']?.toString() ?? 
                           _apiDiagnostics['apiStatusCode']?.toString() ?? 
                           'Desconocido',
                  'isSuccess': (_authDiagnostics['apiStatusCode'] ?? 0) >= 200 && 
                               (_authDiagnostics['apiStatusCode'] ?? 0) < 300,
                },
              if (!apiConnected && (_authDiagnostics['apiError'] != null || _apiDiagnostics['apiError'] != null))
                {
                  'label': 'Error',
                  'value': _authDiagnostics['apiError'] ?? _apiDiagnostics['apiError'],
                  'isSuccess': false,
                },
            ],
          ),
          
          SizedBox(height: 16),
          
          // Sección: Funcionalidades
          _buildDiagnosticSection(
            title: 'Funcionalidades específicas',
            isSuccess: (_authDiagnostics['registerUserConnected'] == true),
            items: [
              {
                'label': 'Registro de usuario',
                'value': _authDiagnostics['registerUserConnected'] == true
                    ? 'Funcional'
                    : 'No disponible',
                'isSuccess': _authDiagnostics['registerUserConnected'] == true,
              },
              if (_authDiagnostics['registerUserStatusCode'] != null)
                {
                  'label': 'Código de respuesta',
                  'value': _authDiagnostics['registerUserStatusCode'].toString(),
                  'isSuccess': (_authDiagnostics['registerUserStatusCode'] ?? 0) >= 200 && 
                               (_authDiagnostics['registerUserStatusCode'] ?? 0) < 300,
                },
            ],
          ),
          
          SizedBox(height: 24),
          
          // Detalles técnicos (expandible)
          ExpansionTile(
            title: Text('Detalles técnicos'),
            leading: Icon(FontAwesomeIcons.code, size: 16),
            children: [
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnóstico Auth Service:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(_authDiagnostics.toString()),
                    SizedBox(height: 16),
                    Text(
                      'Diagnóstico API Service:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(_apiDiagnostics.toString()),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Recomendaciones
          if (!internetConnected || !apiConnected)
            _buildRecommendationsSection(internetConnected, apiConnected),
        ],
      ),
    );
  }
  
  Widget _buildDiagnosticSection({
    required String title,
    required bool isSuccess,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circleXmark,
                size: 16,
                color: isSuccess ? Colors.green : Colors.red,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...items.map((item) => _buildDiagnosticItem(
            label: item['label'],
            value: item['value'],
            isSuccess: item['isSuccess'],
          )),
        ],
      ),
    );
  }
  
  Widget _buildDiagnosticItem({
    required String label,
    required String value,
    required bool isSuccess,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendationsSection(bool internetConnected, bool apiConnected) {
    List<String> recommendations = [];
    
    if (!internetConnected) {
      recommendations.addAll([
        'Verifica tu conexión a Internet',
        'Activa los datos móviles o conéctate a una red WiFi',
        'Reinicia tu dispositivo y router',
      ]);
    } else if (!apiConnected) {
      recommendations.addAll([
        'La API puede estar temporalmente no disponible',
        'Verifica si tienes una versión actualizada de la aplicación',
        'Intenta nuevamente en unos minutos',
      ]);
    }
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FontAwesomeIcons.lightbulb, size: 16, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...recommendations.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(FontAwesomeIcons.circleArrowRight, size: 12, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec,
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: 8),
          Text(
            'La aplicación funcionará en modo local mientras se restablece la conexión.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}