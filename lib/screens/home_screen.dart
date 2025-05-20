// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Importación para Font Awesome
import 'package:provider/provider.dart';
import 'package:pastillero_inteligente/providers/medication_provider.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/models/medication_history_model.dart';
import 'package:pastillero_inteligente/screens/add_medication_screen.dart';
import 'package:pastillero_inteligente/screens/history_screen.dart';
import 'package:pastillero_inteligente/screens/settings_screen.dart';
import 'package:pastillero_inteligente/screens/sos_screen.dart';
import 'package:pastillero_inteligente/screens/medication_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<MedicationProvider>(context, listen: false).fetchMedications();
    } catch (error) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar medicamentos: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PASTILLERO INTELIGENTE'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Consumer<MedicationProvider>(
                  builder: (ctx, medicationProvider, _) {
                    final adherence = medicationProvider.getAdherencePercentage(days: 7);
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${adherence.toInt()}%',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const FaIcon(FontAwesomeIcons.bell, color: Colors.white, size: 20),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.house, size: 20),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.circlePlus, size: 20),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.clockRotateLeft, size: 20),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.gear, size: 20),
            label: 'Config.',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Ya estamos en la pantalla de inicio
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const AddMedicationScreen(),
                ),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const HistoryScreen(),
                ),
              );
              break;
            case 3:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  Widget _buildBody() {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final upcomingMedications = medicationProvider.getUpcomingMedications();
    
    if (upcomingMedications.isEmpty) {
      return _buildEmptyState();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: upcomingMedications.length,
              itemBuilder: (ctx, index) {
                return _buildMedicationCard(upcomingMedications[index], index);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildSOSButton(),
        ],
      ),
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
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: FaIcon(
              FontAwesomeIcons.pills,
              size: 64,
              color: Colors.blue[500],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay medicamentos programados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agregue un nuevo medicamento para comenzar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const AddMedicationScreen(),
                ),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
            label: const Text('AGREGAR MEDICAMENTO'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          const SizedBox(height: 60),
          _buildSOSButton(),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication, int index) {
    // Determinar el estado del medicamento (actual, próxima, pendiente)
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final scheduledTime = medication.scheduledTime;
    
    // Convertir horas a minutos para comparación
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final scheduledMinutes = scheduledTime.hour * 60 + scheduledTime.minute;
    
    // Diferencia en minutos
    final diffMinutes = scheduledMinutes - currentMinutes;
    
    MedicationStatus status;
    if (diffMinutes.abs() <= 30) {
      status = MedicationStatus.current;
    } else if (diffMinutes > 0 && diffMinutes <= 180) {
      status = MedicationStatus.upcoming;
    } else {
      status = MedicationStatus.pending;
    }
    
    // Formatos de tiempo
    final hoursToNextDose = (diffMinutes > 0) ? (diffMinutes / 60).ceil() : 0;
    
    // Colores según estado
    Color borderColor;
    String statusText = '';
    
    switch (status) {
      case MedicationStatus.current:
        borderColor = Colors.green;
        statusText = 'ACTUAL';
        break;
      case MedicationStatus.upcoming:
        borderColor = Colors.amber;
        statusText = 'Próxima toma en $hoursToNextDose horas';
        break;
      case MedicationStatus.pending:
        borderColor = Colors.blue;
        statusText = 'Próxima toma en $hoursToNextDose horas';
        break;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => MedicationDetailScreen(medicationId: medication.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: borderColor,
              width: 8,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: borderColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                medication.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.prescriptionBottleMedical, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    medication.dosage,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              if (status == MedicationStatus.current)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Registrar como tomado
                            _markMedicationAsTaken(medication);
                          },
                          icon: const FaIcon(FontAwesomeIcons.check, size: 16),
                          label: const Text('TOMAR AHORA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Recordar más tarde
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Te recordaremos en 30 minutos')),
                            );
                          },
                          icon: const FaIcon(FontAwesomeIcons.clock, size: 16),
                          label: const Text('RECORDAR MÁS TARDE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOSButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const SOSScreen(),
            ),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.kitMedical, color: Colors.white),
        label: const Text(
          'SOS EMERGENCIA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _markMedicationAsTaken(Medication medication) async {
    if (!mounted) return;
    
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final now = DateTime.now();
    
    // Crear el contexto
    final medContext = MedicationContext(
      location: 'Casa',
      activity: 'Rutina diaria',
      mood: 'Normal',
      adherenceStreak: 1, // Esto debería calcularse
      dayOfWeek: now.weekday,
      isWeekend: (now.weekday == 6 || now.weekday == 7),
    );
    
    final success = await provider.recordMedicationTaken(
      medication.id,
      now,
      medContext,
    );
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('¡Medicamento registrado como tomado!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Error al registrar el medicamento como tomado'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum MedicationStatus {
  current,
  upcoming,
  pending,
}