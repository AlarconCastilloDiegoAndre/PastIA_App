// lib/screens/add_medication_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:pastillero_inteligente/models/medication_model.dart';
import 'package:pastillero_inteligente/providers/medication_provider.dart';

class AddMedicationScreen extends StatefulWidget {
  final Medication? medicationToEdit;
  
  const AddMedicationScreen({Key? key, this.medicationToEdit}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _treatmentDurationController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  List<bool> _selectedDays = [true, true, true, true, true, true, true]; // Todos los días seleccionados por defecto
  int _importance = 3;
  String _category = '';
  String _reminderStrategy = 'standard';
  
  bool _showAdvancedOptions = false;
  bool _isLoading = false;
  
  final _uuid = Uuid();
  
  @override
  void initState() {
    super.initState();
    
    // Si estamos editando, cargar los datos del medicamento
    if (widget.medicationToEdit != null) {
      _nameController.text = widget.medicationToEdit!.name;
      _dosageController.text = widget.medicationToEdit!.dosage;
      _instructionsController.text = widget.medicationToEdit!.instructions;
      _selectedTime = widget.medicationToEdit!.scheduledTime;
      _selectedDays = [...widget.medicationToEdit!.weekDays];
      _importance = widget.medicationToEdit!.importance;
      _category = widget.medicationToEdit!.category ?? '';
      
      if (widget.medicationToEdit!.treatmentDuration != null) {
        _treatmentDurationController.text = widget.medicationToEdit!.treatmentDuration.toString();
      }
      
      _sideEffectsController.text = widget.medicationToEdit!.sideEffects ?? '';
      _reminderStrategy = widget.medicationToEdit!.reminderStrategy;
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _treatmentDurationController.dispose();
    _sideEffectsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicationToEdit == null ? 'Agregar Medicamento' : 'Editar Medicamento'),
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInformationSection(),
                    const SizedBox(height: 24),
                    _buildAdvancedOptionsHeader(),
                    if (_showAdvancedOptions) _buildAdvancedOptionsSection(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información básica',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nombre del medicamento - Implementación corregida
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del medicamento*',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.pills,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
                // Ajusta los constraints para tener un tamaño fijo
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese el nombre del medicamento';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Dosis - Implementación corregida
            TextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: 'Dosis*',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.prescriptionBottleMedical,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                hintText: 'Ej. 1 pastilla, 5ml...',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingrese la dosis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Hora de toma
            ListTile(
              title: const Text('Hora de toma*'),
              subtitle: Text(
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 24),
              ),
              trailing: Container(
                padding: const EdgeInsets.all(4),
                child: const FaIcon(FontAwesomeIcons.clock, size: 16, color: Colors.grey),
              ),
              onTap: _selectTime,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            
            // Días de la semana
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Días de la semana*',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDaySelector(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Instrucciones - Implementación corregida
            TextFormField(
              controller: _instructionsController,
              decoration: InputDecoration(
                labelText: 'Instrucciones',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.circleInfo,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                hintText: 'Ej. Tomar con agua, después de comer...',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 7,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDays[index] = !_selectedDays[index];
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: _selectedDays[index] ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedDays[index] ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedDays[index])
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: FaIcon(
                        FontAwesomeIcons.check,
                        size: 8, // Reducido para mejor ajuste
                        color: Colors.blue,
                      ),
                    ),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedDays[index] ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedOptionsHeader() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Configuración avanzada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              FaIcon(
                _showAdvancedOptions 
                    ? FontAwesomeIcons.chevronUp 
                    : FontAwesomeIcons.chevronDown,
                color: Colors.blue,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Importancia
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Importancia del medicamento (1-5)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _importance.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (value) {
                          setState(() {
                            _importance = value.toInt();
                          });
                        },
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '$_importance',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Menos importante',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Más importante',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Categoría - Implementación corregida
            // Corrección para el DropdownButtonFormField de la categoría:
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Categoría',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.tag,
                    size: 12,
                    color: Colors.grey,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                // No podemos usar suffixIcon en DropdownButtonFormField porque será sobrescrito
              ),
              // Esto es lo importante: añadir explícitamente el icono de flecha
              icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.grey),
              value: _category.isEmpty ? null : _category,
              hint: const Text('Seleccione una categoría'),
              items: [
                'analgésico',
                'antibiótico',
                'antidepresivo',
                'antiinflamatorio',
                'cardiovascular',
                'diabetes',
                'hipertensión',
                'suplemento',
                'otro',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value[0].toUpperCase() + value.substring(1)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _category = newValue ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            
            // Duración del tratamiento - Implementación corregida
            TextFormField(
              controller: _treatmentDurationController,
              decoration: InputDecoration(
                labelText: 'Duración del tratamiento (días)',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.calendar,
                    size: 12,
                    color: Colors.grey,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                hintText: 'Ej. 7, 30, 90... (0 para continuo)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Efectos secundarios - Implementación corregida
            TextFormField(
              controller: _sideEffectsController,
              decoration: InputDecoration(
                labelText: 'Posibles efectos secundarios',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: const FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 12,
                    color: Colors.grey,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Estrategia de recordatorio
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estrategia de recordatorio',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                _buildReminderStrategySelector(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Info sobre ML - Implementación corregida
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: FaIcon(
                      FontAwesomeIcons.circleInfo,
                      color: Colors.blue.shade700,
                      size: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'La configuración avanzada permite que nuestros algoritmos de inteligencia artificial optimicen tus recordatorios y detecten patrones en tu adherencia al tratamiento.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
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

  Widget _buildReminderStrategySelector() {
    final List<Map<String, dynamic>> strategies = [
      {
        'id': 'standard',
        'name': 'Estándar',
        'desc': 'Recordatorios simples a la hora programada',
        'icon': FontAwesomeIcons.bell,
      },
      {
        'id': 'adaptive',
        'name': 'Adaptativo',
        'desc': 'Se ajusta según tus hábitos',
        'icon': FontAwesomeIcons.chartLine,
      },
      {
        'id': 'persistent',
        'name': 'Persistente',
        'desc': 'Recordatorios repetidos hasta tomar',
        'icon': FontAwesomeIcons.repeat,
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: strategies.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> strategy = strategies[index];
        final bool isSelected = _reminderStrategy == strategy['id'];
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _reminderStrategy = strategy['id'] as String;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  strategy['icon'] as IconData,
                  size: 12,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
                const SizedBox(height: 6),
                Text(
                  strategy['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  strategy['desc'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _saveMedication,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 14),
        label: Text(
          widget.medicationToEdit == null ? 'GUARDAR MEDICAMENTO' : 'ACTUALIZAR MEDICAMENTO',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Verificar que al menos un día esté seleccionado
    if (!_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 14),
              SizedBox(width: 8),
              Text('Por favor seleccione al menos un día de la semana'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Crear o actualizar el objeto Medication
    final medication = Medication(
      id: widget.medicationToEdit?.id ?? _uuid.v4(),
      name: _nameController.text,
      dosage: _dosageController.text,
      scheduledTime: _selectedTime,
      weekDays: _selectedDays,
      instructions: _instructionsController.text,
      importance: _importance,
      category: _category.isEmpty ? null : _category,
      treatmentDuration: _treatmentDurationController.text.isEmpty
          ? null
          : int.tryParse(_treatmentDurationController.text),
      sideEffects: _sideEffectsController.text.isEmpty
          ? null
          : _sideEffectsController.text,
      reminderStrategy: _reminderStrategy,
      createdAt: widget.medicationToEdit?.createdAt ?? DateTime.now(),
      updatedAt: widget.medicationToEdit != null ? DateTime.now() : null,
    );
    
    try {
      final medicationProvider = Provider.of<MedicationProvider>(context, listen: false);
      bool success;
      
      if (widget.medicationToEdit == null) {
        // Añadir nuevo medicamento
        success = await medicationProvider.addMedication(medication);
      } else {
        // Actualizar medicamento existente
        success = await medicationProvider.updateMedication(medication);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 14),
                SizedBox(width: 8),
                Text('Error al guardar el medicamento'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              Text('Error: $error'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}