import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SensorSettingsPage extends StatefulWidget {
  const SensorSettingsPage({super.key});

  @override
  State<SensorSettingsPage> createState() => _SensorSettingsPageState();
}

class _SensorSettingsPageState extends State<SensorSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final List<String> _sensors = ['temperature', 'ph level', 'turbidity', 'water level'];
  String? _selectedSensor;

  late TextEditingController _minController;
  late TextEditingController _maxController;
  late TextEditingController _minAlarmController;
  late TextEditingController _maxAlarmController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController();
    _maxController = TextEditingController();
    _minAlarmController = TextEditingController();
    _maxAlarmController = TextEditingController();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minAlarmController.dispose();
    _maxAlarmController.dispose();
    super.dispose();
  }

  Future<void> _loadSensorSettings(String sensor) async {
    final doc = await _firestore.collection('sensorSettings').doc(sensor).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _minController.text = (data['min'] ?? '').toString();
        _maxController.text = (data['max'] ?? '').toString();
        _minAlarmController.text = (data['minAlarm'] ?? '').toString();
        _maxAlarmController.text = (data['maxAlarm'] ?? '').toString();
      });
    } else {
      setState(() {
        _minController.clear();
        _maxController.clear();
        _minAlarmController.clear();
        _maxAlarmController.clear();
      });
    }
  }

  Future<void> _saveSensorSettings() async {
    if (_formKey.currentState!.validate() && _selectedSensor != null) {
      await _firestore.collection('sensorSettings').doc(_selectedSensor).set({
        'min': double.tryParse(_minController.text),
        'max': double.tryParse(_maxController.text),
        'minAlarm': double.tryParse(_minAlarmController.text),
        'maxAlarm': double.tryParse(_maxAlarmController.text),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensor settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextSelectionTheme(
      data: const TextSelectionThemeData(
        cursorColor: Color.fromARGB(255, 62, 72, 180),
        selectionColor: Color.fromARGB(255, 62, 72, 180),
        selectionHandleColor: Color.fromARGB(255, 62, 72, 180),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF10132A),
        body: Column(
          children: [
            _buildHeader('Sensor Settings'),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSensor,
                      decoration: const InputDecoration(
                        labelText: 'Select Sensor',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white38),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color.fromARGB(255, 62, 72, 180)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1E2247),
                      style: const TextStyle(color: Colors.white),
                      items: _sensors.map((sensor) {
                        return DropdownMenuItem(
                          value: sensor,
                          child: Text(sensor),
                        );
                      }).toList(),
                      onChanged: (sensor) {
                        setState(() {
                          _selectedSensor = sensor;
                        });
                        _loadSensorSettings(sensor!);
                      },
                      validator: (value) =>
                          value == null ? 'Please select a sensor' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildNumberField("Min Value", _minController),
                    _buildNumberField("Max Value", _maxController),
                    _buildNumberField("Min Alarm Value", _minAlarmController),
                    _buildNumberField("Max Alarm Value", _maxAlarmController),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2247),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white38),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color.fromARGB(255, 62, 72, 180)),
          ),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Enter $label';
          if (double.tryParse(value) == null) return 'Enter a valid number';
          return null;
        },
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 29, 36, 107),
            Color.fromARGB(255, 62, 72, 180)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _saveSensorSettings,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            child: Center(
              child: Text(
                "Save Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
