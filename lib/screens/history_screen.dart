// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Importación de Font Awesome
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pastillero_inteligente/providers/medication_provider.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _medicationFilter = 'todos';
  String _periodFilter = 'semana';
  String _statusFilter = 'todos';
  int? _expandedHistoryId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        // Añadido icono de atrás con Font Awesome
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildStatistics(),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final provider = Provider.of<MedicationProvider>(context);
    final medications = provider.medications;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.pills, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text(
                          'Medicamento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _medicationFilter,
                        isExpanded: true,
                        underline: Container(),
                        // Añadido icono de flecha desplegable
                        icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.grey),
                        items: [
                          const DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          ...medications.map((med) => DropdownMenuItem(
                            value: med.id,
                            child: Text(med.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _medicationFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.calendarDays, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text(
                          'Período',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _periodFilter,
                        isExpanded: true,
                        underline: Container(),
                        // Añadido icono de flecha desplegable
                        icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.grey),
                        items: const [
                          DropdownMenuItem(
                            value: 'semana',
                            child: Text('Última semana'),
                          ),
                          DropdownMenuItem(
                            value: 'mes',
                            child: Text('Último mes'),
                          ),
                          DropdownMenuItem(
                            value: 'todo',
                            child: Text('Todo'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _periodFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.filter, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        const Text(
                          'Estado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isExpanded: true,
                        underline: Container(),
                        // Añadido icono de flecha desplegable
                        icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.grey),
                        items: const [
                          DropdownMenuItem(
                            value: 'todos',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'tomados',
                            child: Text('Tomados'),
                          ),
                          DropdownMenuItem(
                            value: 'no-tomados',
                            child: Text('No tomados'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final provider = Provider.of<MedicationProvider>(context);
    final filteredHistory = _getFilteredHistory(provider);
    
    final totalItems = filteredHistory.length;
    final takenItems = filteredHistory.where((item) => item.wasTaken).length;
    final adherence = totalItems > 0 ? (takenItems / totalItems * 100).round() : 0;
    
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Registros', 
              totalItems.toString(), 
              icon: FontAwesomeIcons.clipboardList
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Tomados', 
              takenItems.toString(), 
              color: Colors.green,
              icon: FontAwesomeIcons.check
            ),
          ),
          Expanded(
            child: _buildStatCard(
              'Adherencia', 
              '$adherence%', 
              color: _getAdherenceColor(adherence),
              icon: FontAwesomeIcons.chartPie
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, {Color color = Colors.blue, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Añadido icono con Font Awesome
          FaIcon(icon, size: 14, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20, // Reducido ligeramente para mejor ajuste visual
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final provider = Provider.of<MedicationProvider>(context);
    final filteredHistory = _getFilteredHistory(provider);
    
    if (filteredHistory.isEmpty) {
      return _buildEmptyState();
    }
    
    // Detectar patrones usando ML
    final patterns = _detectPatterns(filteredHistory);
    
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        if (patterns.isNotEmpty) _buildPatternsSection(patterns),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: const [
              FaIcon(FontAwesomeIcons.list, size: 14, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Registro de medicamentos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...filteredHistory.map((item) => _buildHistoryItem(item, provider)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            // Reemplazado con Font Awesome
            child: FaIcon(
              FontAwesomeIcons.clockRotateLeft,
              size: 32,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay registros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay registros que coincidan con los filtros seleccionados',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsSection(List<Map<String, dynamic>> patterns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: const [
              FaIcon(FontAwesomeIcons.lightbulb, size: 14, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Patrones detectados',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        ...patterns.map((pattern) => _buildPatternCard(pattern)),
      ],
    );
  }

  Widget _buildPatternCard(Map<String, dynamic> pattern) {
    // Reemplazado con iconos de Font Awesome
    IconData iconData;
    Color iconColor;
    
    switch (pattern['tipo']) {
      case 'adherencia':
        iconData = FontAwesomeIcons.checkCircle;
        iconColor = Colors.green;
        break;
      case 'tiempo':
        iconData = FontAwesomeIcons.clock;
        iconColor = Colors.orange;
        break;
      default:
        iconData = FontAwesomeIcons.circleInfo;
        iconColor = Colors.blue;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                iconData,
                color: iconColor,
                size: 16, // Tamaño reducido para mejor ajuste
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pattern['descripcion'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pattern['recomendacion'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(MedicationHistory item, MedicationProvider provider) {
    final medication = provider.medications.firstWhere(
      (med) => med.id == item.medicationId,
      orElse: () => Medication(
        id: 'unknown',
        name: 'Medicamento desconocido',
        dosage: '',
        scheduledTime: const TimeOfDay(hour: 0, minute: 0),
        weekDays: List.filled(7, false),
        createdAt: DateTime.now(),
      ),
    );
    
    final dateFormatter = DateFormat('HH:mm - dd/MM/yyyy');
    final formattedDate = dateFormatter.format(item.scheduledDateTime);
    
    final isExpanded = _expandedHistoryId == item.id.hashCode;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Encabezado del item (siempre visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedHistoryId = isExpanded ? null : item.id.hashCode;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icono de estado con Font Awesome
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.wasTaken ? Colors.green.shade100 : Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        item.wasTaken ? FontAwesomeIcons.check : FontAwesomeIcons.xmark,
                        size: 16,
                        color: item.wasTaken ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Información básica
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.pills, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              medication.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.clock, size: 10, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Dosis e info adicional
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.prescriptionBottleMedical, 
                            size: 10, 
                            color: Colors.grey
                          ),
                          const SizedBox(width: 4),
                          Text(
                            medication.dosage,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      if (item.wasTaken && item.deviationMinutes != null && item.deviationMinutes != 0)
                        Row(
                          children: [
                            FaIcon(
                              item.deviationMinutes! > 0 
                                  ? FontAwesomeIcons.arrowUp 
                                  : FontAwesomeIcons.arrowDown,
                              size: 10,
                              color: item.deviationMinutes! > 0 ? Colors.orange : Colors.blue,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.deviationMinutes! > 0
                                  ? '+${item.deviationMinutes} min'
                                  : '${item.deviationMinutes} min',
                              style: TextStyle(
                                fontSize: 12,
                                color: item.deviationMinutes! > 0
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  // Icono para expandir/colapsar
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FaIcon(
                      isExpanded ? FontAwesomeIcons.chevronUp : FontAwesomeIcons.chevronDown,
                      size: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Detalles expandibles
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  const Divider(),
                  if (item.wasTaken) _buildTakenDetails(item) else _buildSkippedDetails(item),
                  const SizedBox(height: 12),
                  _buildActionButtons(item),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTakenDetails(MedicationHistory item) {
    return Column(
      children: [
        // Desviación de tiempo
        _buildDetailRow(
          icon: FontAwesomeIcons.clock,
          label: 'Desviación:',
          value: item.deviationMinutes == null || item.deviationMinutes == 0
              ? 'A tiempo'
              : item.deviationMinutes! > 0
                  ? '${item.deviationMinutes} min después'
                  : '${item.deviationMinutes!.abs()} min antes',
          textColor: item.deviationMinutes == null || item.deviationMinutes == 0
              ? Colors.green
              : item.deviationMinutes! > 0
                  ? Colors.orange
                  : Colors.blue,
        ),
        
        // Contexto si está disponible
        if (item.context != null) ...[
          if (item.context!.location != null)
            _buildDetailRow(
              icon: FontAwesomeIcons.locationDot,
              label: 'Ubicación:', 
              value: item.context!.location!
            ),
          if (item.context!.activity != null)
            _buildDetailRow(
              icon: FontAwesomeIcons.personWalking,
              label: 'Actividad:', 
              value: item.context!.activity!
            ),
          if (item.context!.mood != null)
            _buildDetailRow(
              icon: FontAwesomeIcons.faceSmile,
              label: 'Estado de ánimo:', 
              value: item.context!.mood!
            ),
        ],
      ],
    );
  }

  Widget _buildSkippedDetails(MedicationHistory item) {
    return _buildDetailRow(
      icon: FontAwesomeIcons.circleExclamation,
      label: 'Razón:',
      value: item.reasonNotTaken ?? 'No especificada',
      textColor: Colors.red,
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label, 
    required String value, 
    Color? textColor
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          FaIcon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(MedicationHistory item) {
    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () {
              // Lógica para cambiar el estado del medicamento
              _showConfirmDialog(
                context,
                '¿Cambiar estado?',
                item.wasTaken
                    ? '¿Realmente quieres marcar este medicamento como no tomado?'
                    : '¿Realmente quieres marcar este medicamento como tomado?',
                () {
                  // Implementar la lógica para cambiar el estado
                  setState(() {
                    // En una implementación real, esto se guardaría en la base de datos
                  });
                },
              );
            },
            icon: FaIcon(
              item.wasTaken ? FontAwesomeIcons.xmark : FontAwesomeIcons.check,
              size: 12,
              color: item.wasTaken ? Colors.red : Colors.green,
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: Text(
              item.wasTaken ? 'Marcar como no tomado' : 'Marcar como tomado',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextButton.icon(
            onPressed: () {
              // Implementar lógica para agregar notas
            },
            icon: const FaIcon(FontAwesomeIcons.noteSticky, size: 12, color: Colors.blue),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            label: const Text(
              'Agregar nota',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String message, Function onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.circleQuestion, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            icon: const FaIcon(FontAwesomeIcons.ban, size: 14),
            label: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            icon: const FaIcon(FontAwesomeIcons.check, size: 14),
            label: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  List<MedicationHistory> _getFilteredHistory(MedicationProvider provider) {
    List<MedicationHistory> filteredHistory = [...provider.history];
    
    // Filtrar por medicamento
    if (_medicationFilter != 'todos') {
      filteredHistory = filteredHistory
          .where((item) => item.medicationId == _medicationFilter)
          .toList();
    }
    
    // Filtrar por período
    if (_periodFilter != 'todo') {
      final DateTime cutoffDate;
      if (_periodFilter == 'semana') {
        cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      } else if (_periodFilter == 'mes') {
        cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      } else {
        cutoffDate = DateTime(1900); // Todos los registros
      }
      
      filteredHistory = filteredHistory
          .where((item) => item.scheduledDateTime.isAfter(cutoffDate))
          .toList();
    }
    
    // Filtrar por estado
    if (_statusFilter != 'todos') {
      filteredHistory = filteredHistory
          .where((item) => _statusFilter == 'tomados' ? item.wasTaken : !item.wasTaken)
          .toList();
    }
    
    // Ordenar por fecha (más reciente primero)
    filteredHistory.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
    
    return filteredHistory;
  }

  List<Map<String, dynamic>> _detectPatterns(List<MedicationHistory> history) {
    // Esta sería una implementación simulada de detección de patrones
    // En una implementación real, esto usaría los modelos de ML (Isolation Forest, etc.)
    
    // Para el ejemplo, vamos a crear algunos patrones simulados
    List<Map<String, dynamic>> patterns = [];
    
    // Solo mostrar patrones si hay suficientes datos
    if (history.length > 5) {
      // Patrón de mejora de adherencia
      patterns.add({
        'tipo': 'adherencia',
        'descripcion': 'Tu adherencia ha mejorado un 15% esta semana',
        'recomendacion': 'Continúa así, vas por buen camino',
      });
      
      // Patrón de tiempo
      if (history.where((item) => item.wasTaken && item.deviationMinutes != null).length > 3) {
        patterns.add({
          'tipo': 'tiempo',
          'descripcion': 'Tomas los medicamentos 5 minutos antes cuando estás en el trabajo',
          'recomendacion': '¿Quieres ajustar el horario para cuando estás en el trabajo?',
        });
      }
    }
    
    return patterns;
  }

  Color _getAdherenceColor(int adherence) {
    if (adherence >= 90) return Colors.green;
    if (adherence >= 75) return Colors.orange;
    return Colors.red;
  }
}