// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pastillero_inteligente/services/auth_service.dart';
import 'dart:math' as math;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Estados para las configuraciones
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  TimeOfDay _routineStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _routineEnd = const TimeOfDay(hour: 22, minute: 0);
  String _timeZone = 'America/Mexico_City';
  String _notificationMode = 'push';
  String _privacyLevel = 'normal';
  bool _mlDataEnabled = true;
  String _defaultReminderStrategy = 'adaptive';
  
  // Contactos de emergencia (simulados)
  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      'id': 1,
      'name': 'Dr. García',
      'phone': '+52 123 456 7890',
      'type': 'médico',
    },
    {
      'id': 2,
      'name': 'María Rodríguez',
      'phone': '+52 098 765 4321',
      'type': 'familiar',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        // Añadido icono de atrás con Font Awesome
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildProfileSection(),
          _buildNotificationsSection(),
          _buildDailyRoutineSection(),
          _buildMachineLearningSection(),
          _buildDeviceInfoSection(),
          _buildEmergencyContactsSection(),
          _buildMedicalInfoSection(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final authService = AuthService();
    
    return _buildSection(
      title: 'Perfil de Usuario',
      icon: FontAwesomeIcons.userCircle,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: FaIcon(
                        FontAwesomeIcons.user,
                        size: 24,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.userName ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (authService.userEmail != null)
                          Text(
                            authService.userEmail!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        Text(
                          'ID: ${authService.userId?.substring(0, math.min(8, authService.userId?.length ?? 0)) ?? 'No disponible'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showEditProfileDialog(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.userEdit, size: 16),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: const Text('EDITAR PERFIL'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutConfirmation(context);
                  },
                  icon: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 16, color: Colors.red),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.red,
                  ),
                  label: const Text('CERRAR SESIÓN'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSection(
      title: 'Notificaciones',
      icon: FontAwesomeIcons.bell,
      children: [
        _buildSwitchTile(
          title: 'Activar notificaciones',
          subtitle: 'Recibe alertas de tus medicamentos',
          value: _notificationsEnabled,
          icon: FontAwesomeIcons.solidBell,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Sonido',
          subtitle: 'Reproduce un sonido con las notificaciones',
          value: _soundEnabled,
          icon: FontAwesomeIcons.volumeHigh,
          onChanged: (value) {
            setState(() {
              _soundEnabled = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Vibración',
          subtitle: 'Vibra con las notificaciones',
          value: _vibrationEnabled,
          icon: FontAwesomeIcons.mobileScreen,
          onChanged: (value) {
            setState(() {
              _vibrationEnabled = value;
            });
          },
        ),
        _buildSettingTitle('Modo de notificación', FontAwesomeIcons.envelope),
        _buildOptionSelector(
          options: [
            {
              'id': 'push',
              'title': 'Push',
              'subtitle': 'Notificaciones normales',
              'icon': FontAwesomeIcons.bell,
            },
            {
              'id': 'sms',
              'title': 'SMS',
              'subtitle': 'Mensajes de texto',
              'icon': FontAwesomeIcons.comment,
            },
            {
              'id': 'email',
              'title': 'Email',
              'subtitle': 'Correo electrónico',
              'icon': FontAwesomeIcons.envelope,
            },
          ],
          selectedId: _notificationMode,
          onSelected: (value) {
            setState(() {
              _notificationMode = value;
            });
          },
        ),
        _buildSettingTitle('Nivel de privacidad', FontAwesomeIcons.lock),
        _buildOptionSelector(
          options: [
            {
              'id': 'normal',
              'title': 'Normal',
              'subtitle': 'Muestra el nombre del medicamento en las notificaciones',
              'icon': FontAwesomeIcons.eyeSlash,
            },
            {
              'id': 'alto',
              'title': 'Alto',
              'subtitle': 'Oculta el nombre del medicamento en las notificaciones',
              'icon': FontAwesomeIcons.eye,
            },
          ],
          selectedId: _privacyLevel,
          onSelected: (value) {
            setState(() {
              _privacyLevel = value;
            });
          },
          columns: 2,
        ),
      ],
    );
  }

  Widget _buildDailyRoutineSection() {
    return _buildSection(
      title: 'Rutina Diaria',
      icon: FontAwesomeIcons.calendar,
      children: [
        _buildSettingTitle('Horario activo', FontAwesomeIcons.clockRotateLeft),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        FaIcon(FontAwesomeIcons.solidSun, size: 12, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Inicio del día',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: _routineStart,
                        );
                        if (time != null) {
                          setState(() {
                            _routineStart = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_routineStart.hour.toString().padLeft(2, '0')}:${_routineStart.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        FaIcon(FontAwesomeIcons.solidMoon, size: 12, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Fin del día',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: _routineEnd,
                        );
                        if (time != null) {
                          setState(() {
                            _routineEnd = time;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_routineEnd.hour.toString().padLeft(2, '0')}:${_routineEnd.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              FaIcon(FontAwesomeIcons.circleInfo, size: 12, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Establece tu horario activo para optimizar las notificaciones.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSettingTitle('Zona horaria', FontAwesomeIcons.earthAmericas),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButtonFormField<String>(
            value: _timeZone,
            icon: const FaIcon(FontAwesomeIcons.chevronDown, size: 14, color: Colors.grey),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: const FaIcon(
                  FontAwesomeIcons.globe,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(
                value: 'America/Mexico_City',
                child: Text('Ciudad de México (GMT-6)'),
              ),
              DropdownMenuItem(
                value: 'America/New_York',
                child: Text('Nueva York (GMT-5)'),
              ),
              DropdownMenuItem(
                value: 'America/Los_Angeles',
                child: Text('Los Ángeles (GMT-8)'),
              ),
              DropdownMenuItem(
                value: 'Europe/Madrid',
                child: Text('Madrid (GMT+1)'),
              ),
              DropdownMenuItem(
                value: 'Asia/Tokyo',
                child: Text('Tokio (GMT+9)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _timeZone = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMachineLearningSection() {
    return _buildSection(
      title: 'Inteligencia Artificial',
      icon: FontAwesomeIcons.brain,
      children: [
        _buildSwitchTile(
          title: 'Recopilación de datos',
          subtitle: 'Permitir análisis para mejorar recordatorios',
          value: _mlDataEnabled,
          icon: FontAwesomeIcons.chartLine,
          onChanged: (value) {
            setState(() {
              _mlDataEnabled = value;
            });
          },
        ),
        _buildSettingTitle('Estrategia de recordatorio predeterminada', FontAwesomeIcons.bell),
        Column(
          children: [
            _buildRadioTile(
              title: 'Estándar',
              subtitle: 'Recordatorios simples a la hora programada',
              value: 'standard',
              groupValue: _defaultReminderStrategy,
              icon: FontAwesomeIcons.bell,
              onChanged: (value) {
                setState(() {
                  _defaultReminderStrategy = value!;
                });
              },
            ),
            _buildRadioTile(
              title: 'Adaptativo',
              subtitle: 'Se ajusta según tus hábitos y patrones de toma',
              value: 'adaptive',
              groupValue: _defaultReminderStrategy,
              icon: FontAwesomeIcons.chartLine,
              onChanged: (value) {
                setState(() {
                  _defaultReminderStrategy = value!;
                });
              },
            ),
            _buildRadioTile(
              title: 'Persistente',
              subtitle: 'Recordatorios repetidos hasta que tomes el medicamento',
              value: 'persistent',
              groupValue: _defaultReminderStrategy,
              icon: FontAwesomeIcons.repeat,
              onChanged: (value) {
                setState(() {
                  _defaultReminderStrategy = value!;
                });
              },
            ),
          ],
        ),
        if (_mlDataEnabled)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FaIcon(
                        FontAwesomeIcons.circleInfo,
                        color: Colors.blue.shade700,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La app utiliza algoritmos de aprendizaje para:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoBullet('Detectar patrones de adherencia'),
                  _buildInfoBullet('Optimizar horarios de recordatorios'),
                  _buildInfoBullet('Identificar factores que afectan tu rutina'),
                  const SizedBox(height: 8),
                  Text(
                    'Todos los datos son procesados localmente y de forma anónima.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceInfoSection() {
    return _buildNavigationSection(
      title: 'Información del dispositivo',
      subtitle: 'Configurar conexión con el pastillero',
      icon: FontAwesomeIcons.microchip,
      onTap: () {
        // Navegar a la pantalla de configuración del dispositivo
      },
    );
  }

  Widget _buildEmergencyContactsSection() {
    return _buildNavigationSection(
      title: 'Contactos de emergencia',
      subtitle: 'Gestionar contactos para emergencias (${_emergencyContacts.length})',
      icon: FontAwesomeIcons.addressBook,
      onTap: () {
        // Navegar a la pantalla de contactos de emergencia
      },
    );
  }

  Widget _buildMedicalInfoSection() {
    return _buildNavigationSection(
      title: 'Información médica',
      subtitle: 'Gestionar información médica personal',
      icon: FontAwesomeIcons.userDoctor,
      onTap: () {
        // Navegar a la pantalla de información médica
      },
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'Acerca de',
      icon: FontAwesomeIcons.circleInfo,
      children: [
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.code, size: 16, color: Colors.grey),
          title: const Text('Versión'),
          trailing: const Text('1.0.0'),
          dense: true,
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Mostrar política de privacidad
                  },
                  icon: const FaIcon(FontAwesomeIcons.shield, size: 14),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text('Política de privacidad'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Mostrar términos de uso
                  },
                  icon: const FaIcon(FontAwesomeIcons.fileLines, size: 14),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text('Términos de uso'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children, required IconData icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                FaIcon(icon, size: 16, color: Colors.blue), // Icono con Font Awesome
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNavigationSection({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        leading: FaIcon(icon, size: 16, color: Colors.blue), // Icono con Font Awesome
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const FaIcon(FontAwesomeIcons.chevronRight, size: 14, color: Colors.grey), // Icono con Font Awesome
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: FaIcon(icon, size: 16, color: Colors.grey), // Icono con Font Awesome
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
          FaIcon(icon, size: 14, color: Colors.grey), // Icono con Font Awesome
        ],
      ),
    );
  }

  Widget _buildSettingTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: Colors.grey), // Icono con Font Awesome
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSelector({
    required List<Map<String, dynamic>> options,
    required String selectedId,
    required ValueChanged<String> onSelected,
    int columns = 3,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 0.9,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedId == option['id'];
          
          return GestureDetector(
            onTap: () => onSelected(option['id']),
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
                  // Añadido icono con Font Awesome
                  FaIcon(
                    option['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    option['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option['subtitle'],
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.blue.shade600 : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditProfileDialog(BuildContext context) {
    final authService = AuthService();
    
    final nameController = TextEditingController(text: authService.userName);
    final emailController = TextEditingController(text: authService.userEmail);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final success = await authService.updateUserInfo(
                name: nameController.text,
                email: emailController.text.isNotEmpty ? emailController.text : null,
              );
              
              if (success) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfil actualizado')),
                );
                setState(() {}); // Actualizar UI
              } else {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al actualizar perfil')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión? Tus datos locales se mantendrán.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final authService = AuthService();
              await authService.logout();
              
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}