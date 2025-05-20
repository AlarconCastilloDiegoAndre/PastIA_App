// lib/screens/medication_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/providers/medication_provider.dart';
import 'package:pastillero_inteligente/screens/add_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String medicationId;
  
  const MedicationDetailScreen({
    Key? key,
    required this.medicationId,
  }) : super(key: key);

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOptions = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, provider, child) {
        final medication = provider.medications.firstWhere(
          (med) => med.id == widget.medicationId,
          orElse: () => Medication(
            id: 'not_found',
            name: 'Medicamento no encontrado',
            dosage: '',
            scheduledTime: const TimeOfDay(hour: 0, minute: 0),
            weekDays: List.filled(7, false),
            createdAt: DateTime.now(),
          ),
        );
        
        if (medication.id == 'not_found') {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detalle no encontrado'),
            ),
            body: const Center(
              child: Text('El medicamento no existe o ha sido eliminado'),
            ),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detalle Medicamento'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  setState(() {
                    _showOptions = !_showOptions;
                  });
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // Resumen del medicamento
                  _buildMedicationSummary(medication),
                  
                  // Pestañas
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: const [
                      Tab(text: 'Detalles'),
                      Tab(text: 'Estadísticas'),
                      Tab(text: 'Patrones'),
                    ],
                  ),
                  
                  // Contenido de la pestaña seleccionada
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Pestaña Detalles
                        _buildDetailsTab(medication),
                        
                        // Pestaña Estadísticas
                        _buildStatisticsTab(medication, provider),
                        
                        // Pestaña Patrones
                        _buildPatternsTab(medication, provider),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Menú de opciones flotante
              if (_showOptions)
                Positioned(
                  top: 0,
                  right: 8,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOptionItem(
                          'Editar medicamento',
                          Icons.edit,
                          () {
                            setState(() => _showOptions = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => AddMedicationScreen(
                                  medicationToEdit: medication,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildOptionItem(
                          'Desactivar temporalmente',
                          Icons.pause_circle_outline,
                          () {
                            setState(() => _showOptions = false);
                            _showTemporaryDisableDialog();
                          },
                        ),
                        _buildOptionItem(
                          'Eliminar medicamento',
                          Icons.delete_outline,
                          () {
                            setState(() => _showOptions = false);
                            _showDeleteConfirmationDialog(medication);
                          },
                          textColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicationSummary(Medication medication) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medication.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                medication.dosage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              if (medication.category != null && medication.category!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    medication.category!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${medication.scheduledTime.hour.toString().padLeft(2, '0')}:${medication.scheduledTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  for (int i = 0; i < medication.weekDays.length; i++)
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: medication.weekDays[i]
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                      ),
                      child: Center(
                        child: Text(
                          ['L', 'M', 'X', 'J', 'V', 'S', 'D'][i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: medication.weekDays[i]
                                ? Colors.blue.shade800
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Medication medication) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instrucciones
          _buildDetailCard(
            title: 'Instrucciones',
            content: Text(
              medication.instructions.isEmpty
                  ? 'No se han especificado instrucciones'
                  : medication.instructions,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          
          // Duración del tratamiento
          _buildDetailCard(
            title: 'Duración del tratamiento',
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de inicio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy').format(medication.createdAt),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Fecha fin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      medication.treatmentDuration != null &&
                              medication.treatmentDuration! > 0
                          ? DateFormat('dd/MM/yyyy').format(
                              medication.createdAt.add(
                                Duration(days: medication.treatmentDuration!),
                              ),
                            )
                          : 'Tratamiento continuo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Configuración avanzada
          _buildDetailCard(
            title: 'Configuración avanzada',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nivel de importancia
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nivel de importancia',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < medication.importance
                                ? Colors.blue
                                : Colors.grey.shade300,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: index < medication.importance
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Estrategia de recordatorio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estrategia de recordatorio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getReminderStrategyLabel(medication.reminderStrategy),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Efectos secundarios
                const Text(
                  'Posibles efectos secundarios',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medication.sideEffects ?? 'No se han especificado efectos secundarios',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Última modificación
                if (medication.updatedAt != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Última modificación: ${DateFormat('dd/MM/yyyy').format(medication.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(Medication medication, MedicationProvider provider) {
    // Obtener historial relacionado con este medicamento
    final medicationHistory = provider.history
        .where((item) => item.medicationId == medication.id)
        .toList();
    
    // Calcular estadísticas
    final int totalRecords = medicationHistory.length;
    final int takenRecords = medicationHistory
        .where((item) => item.wasTaken)
        .length;
    
    final double adherencePercentage = totalRecords > 0
        ? (takenRecords / totalRecords) * 100
        : 0;
    
    // Calcular adherencia de la última semana
    final DateTime oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
    final List<MedicationHistory> recentHistory = medicationHistory
        .where((item) => item.scheduledDateTime.isAfter(oneWeekAgo))
        .toList();
    
    final int recentTotal = recentHistory.length;
    final int recentTaken = recentHistory
        .where((item) => item.wasTaken)
        .length;
    
    final double recentAdherencePercentage = recentTotal > 0
        ? (recentTaken / recentTotal) * 100
        : 0;
    
    // Determinar tendencia
    String trend = 'estable';
    if (recentAdherencePercentage > adherencePercentage + 5) {
      trend = 'mejora';
    } else if (recentAdherencePercentage < adherencePercentage - 5) {
      trend = 'deterioro';
    }
    
    // Calcular desviación de tiempo promedio
    final takenItems = medicationHistory
        .where((item) => item.wasTaken && item.deviationMinutes != null)
        .toList();
    
    final int deviationSum = takenItems.fold(
      0,
      (prev, item) => prev + (item.deviationMinutes ?? 0),
    );
    
    final double averageDeviation = takenItems.isNotEmpty
        ? deviationSum / takenItems.length
        : 0;
    
    // Análisis de razones de omisión
    final skippedItems = medicationHistory
        .where((item) => !item.wasTaken)
        .toList();
    
    final Map<String, int> reasonCounts = {};
    for (var item in skippedItems) {
      final reason = item.reasonNotTaken ?? 'No especificada';
      reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
    }
    
    final List<Map<String, dynamic>> reasonStats = reasonCounts.entries
        .map((entry) => {
          'reason': entry.key,
          'count': entry.value,
          'percentage': (entry.value / skippedItems.length) * 100,
        })
        .toList();
    
    reasonStats.sort((a, b) => b['count'].compareTo(a['count']));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de adherencia
          _buildDetailCard(
            title: 'Adherencia al tratamiento',
            content: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${adherencePercentage.round()}%',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _getAdherenceColor(adherencePercentage),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTrendIndicator(trend),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Última semana',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '${recentAdherencePercentage.round()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getAdherenceColor(recentAdherencePercentage),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Gráfica simulada de adherencia por día
                Container(
                  height: 120,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarChartColumn('L', 75),
                      _buildBarChartColumn('M', 80),
                      _buildBarChartColumn('X', 70),
                      _buildBarChartColumn('J', 85),
                      _buildBarChartColumn('V', 90),
                      _buildBarChartColumn('S', 75),
                      _buildBarChartColumn('D', 80),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Estadísticas adicionales
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Días totales',
                        totalRecords.toString(),
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Tomados',
                        takenRecords.toString(),
                        color: Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        'Omitidos',
                        (totalRecords - takenRecords).toString(),
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Desviación de tiempo
          _buildDetailCard(
            title: 'Desviación de tiempo',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      averageDeviation.round() == 0
                          ? 'A tiempo'
                          : '${averageDeviation > 0 ? "+" : ""}${averageDeviation.round()} min',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: averageDeviation.round() == 0
                            ? Colors.green
                            : averageDeviation > 0
                                ? Colors.orange
                                : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'desviación promedio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Escala visual
                Stack(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    // Línea de tiempo programado
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.5 - 36,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: Colors.grey,
                      ),
                    ),
                    // Indicador de desviación promedio
                    Positioned(
                      left: MediaQuery.of(context).size.width * 0.5 - 36 + 
                          (averageDeviation * 2).round(),
                      top: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '-30 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Hora programada',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '+30 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Razones de omisión
          if (reasonStats.isNotEmpty)
            _buildDetailCard(
              title: 'Razones de omisión',
              content: Column(
                children: reasonStats.map((stat) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stat['reason'],
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${stat['percentage'].round()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: stat['percentage'] / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatternsTab(Medication medication, MedicationProvider provider) {
    // Detectar patrones para este medicamento (simulado)
    final patterns = _detectPatterns(medication, provider);
    
    if (patterns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                size: 36,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay patrones detectados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 250,
              child: Text(
                'Necesitamos más datos para detectar patrones en tu uso de este medicamento.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información sobre patrones
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Estos patrones han sido detectados a través de algoritmos de aprendizaje automático que analizan tu historial de tomas de medicamentos.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de patrones detectados
          ...patterns.map((pattern) => _buildPatternCard(pattern)).toList(),
        ],
      ),
    );
  }

  Widget _buildDetailCard({required String title, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartColumn(String label, double value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: value * 0.8,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, {Color color = Colors.blue}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    IconData iconData;
    Color color;
    String label;
    
    switch (trend) {
      case 'mejora':
        iconData = Icons.trending_up;
        color = Colors.green;
        label = 'Mejorando';
        break;
      case 'deterioro':
        iconData = Icons.trending_down;
        color = Colors.red;
        label = 'Deterioro';
        break;
      default:
        iconData = Icons.trending_flat;
        color = Colors.blue;
        label = 'Estable';
    }
    
    return Row(
      children: [
        Icon(
          iconData,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }

Widget _buildPatternCard(Map<String, dynamic> pattern) {
    IconData iconData;
    Color iconColor;
    
    switch (pattern['tipo']) {
      case 'tiempo':
        iconData = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case 'adherencia':
        iconData = Icons.check_circle_outline;
        iconColor = Colors.red;
        break;
      case 'contexto':
        iconData = Icons.location_on;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.info_outline;
        iconColor = Colors.blue;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pattern['descripcion'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${pattern['confianza']}% confianza',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pattern['sugerencia'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyPatternSuggestion(pattern);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionButtonColor(pattern['accion']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        _getActionButtonLabel(pattern['accion']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _applyPatternSuggestion(Map<String, dynamic> pattern) {
    // Implementación simulada
    switch (pattern['accion']) {
      case 'ajustar':
        // Mostrar diálogo para confirmar ajuste de horario
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ajustar horario'),
            content: Text('¿Realmente quieres ajustar el horario a ${pattern['sugerencia'].split('a las ').last}?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Implementar ajuste de horario
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Horario ajustado correctamente')),
                  );
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
        break;
      case 'recordar':
        // Activar recordatorios persistentes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recordatorios persistentes activados')),
        );
        break;
      case 'informar':
        // Solo informar al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Información registrada')),
        );
        break;
    }
  }

  Widget _buildOptionItem(String label, IconData icon, VoidCallback onTap, {Color textColor = Colors.black87}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAdherenceColor(double adherence) {
    if (adherence >= 90) return Colors.green;
    if (adherence >= 75) return Colors.orange;
    return Colors.red;
  }

  String _getReminderStrategyLabel(String strategy) {
    switch (strategy) {
      case 'adaptive':
        return 'Adaptativa';
      case 'persistent':
        return 'Persistente';
      default:
        return 'Estándar';
    }
  }

  Color _getActionButtonColor(String action) {
    switch (action) {
      case 'ajustar':
        return Colors.orange;
      case 'recordar':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getActionButtonLabel(String action) {
    switch (action) {
      case 'ajustar':
        return 'Ajustar horario';
      case 'recordar':
        return 'Activar recordatorios persistentes';
      default:
        return 'Entendido';
    }
  }

  List<Map<String, dynamic>> _detectPatterns(Medication medication, MedicationProvider provider) {
    // Esta sería una implementación simulada de detección de patrones
    // En una implementación real, esto usaría los modelos de ML (Isolation Forest, etc.)
    
    // Extraer el historial para este medicamento
    final history = provider.history
        .where((item) => item.medicationId == medication.id)
        .toList();
    
    // Solo mostrar patrones si hay suficientes datos
    if (history.length < 5) {
      return [];
    }
    
    // Para el ejemplo, vamos a crear algunos patrones simulados
    return [
      {
        'tipo': 'tiempo',
        'descripcion': 'Sueles tomar este medicamento 5-10 minutos antes de lo programado',
        'sugerencia': 'Reajustar el horario a las 09:50',
        'accion': 'ajustar',
        'confianza': 87,
      },
      {
        'tipo': 'adherencia',
        'descripcion': 'Los fines de semana tienes 30% menos adherencia',
        'sugerencia': 'Activar recordatorios persistentes en sábado y domingo',
        'accion': 'recordar',
        'confianza': 92,
      },
      {
        'tipo': 'contexto',
        'descripcion': 'Mayor probabilidad de omisión cuando estás fuera de casa',
        'sugerencia': 'Preparar dosis para llevar cuando salgas',
        'accion': 'informar',
        'confianza': 78,
      },
    ];
  }

  void _showDeleteConfirmationDialog(Medication medication) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicamento'),
        content: Text('¿Realmente quieres eliminar "${medication.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              final provider = Provider.of<MedicationProvider>(context, listen: false);
              final success = await provider.deleteMedication(medication.id);
              
              if (success) {
                Navigator.of(context).pop(); // Regresar a la pantalla anterior
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al eliminar el medicamento')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showTemporaryDisableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar temporalmente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selecciona el período de desactivación:'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('1 día'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento desactivado por 1 día')),
                );
              },
            ),
            ListTile(
              title: const Text('3 días'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento desactivado por 3 días')),
                );
              },
            ),
            ListTile(
              title: const Text('1 semana'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento desactivado por 1 semana')),
                );
              },
            ),
            ListTile(
              title: const Text('Hasta nuevo aviso'),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Medicamento desactivado hasta nuevo aviso')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}