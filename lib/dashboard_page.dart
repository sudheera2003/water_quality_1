import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sensor_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _temperature = 0.0;
  double _ph = 0.0;
  double _turbidity = 0.0;
  double _waterLevel = 0.0;

  Map<String, Map<String, double>> sensorLimits = {
    'temperature': {'min': 0, 'max': 50, 'minAlarm': 0, 'maxAlarm': 50},
    'ph_level': {'min': 0, 'max': 14, 'minAlarm': 0, 'maxAlarm': 14},
    'turbidity': {'min': 0, 'max': 100, 'minAlarm': 0, 'maxAlarm': 100},
    'water_level': {'min': 0, 'max': 200, 'minAlarm': 0, 'maxAlarm': 200},
  };

  bool _limitsLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchSensorLimits().then((_) {
      setState(() {
        _limitsLoaded = true;
      });
    });
    _setupRealtimeListener();
  }

  Future<void> _fetchSensorLimits() async {
    try {
      final sensors = ['temperature', 'ph_level', 'turbidity', 'water_level'];
      for (var sensor in sensors) {
        final doc =
            await _firestore.collection('sensorSettings').doc(sensor).get();
        if (doc.exists) {
          print('Fetched $sensor: ${doc.data()}'); // Debug print
          final data = doc.data();
          if (data != null) {
            sensorLimits[sensor] = {
              'min': (data['min'] as num?)?.toDouble() ?? 0.0,
              'max': (data['max'] as num?)?.toDouble() ?? 100.0,
              'minAlarm': (data['minAlarm'] as num?)?.toDouble() ?? 0.0,
              'maxAlarm': (data['maxAlarm'] as num?)?.toDouble() ?? 100.0,
            };
          }
        } else {
          print('Document $sensor does not exist'); // Debug print
        }
      }
    } catch (e) {
      print('Error fetching sensor limits: $e'); // Debug print
    }
  }

  void _setupRealtimeListener() {
    _firestore
        .collection('sensorReadings')
        .doc('latest')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data();
        if (data != null) {
          setState(() {
            // Using the actual field names from your Firestore
            _temperature = (data['temp'] as num?)?.toDouble() ?? 0.0;
            _ph = (data['ph'] as num?)?.toDouble() ?? 0.0;
            _turbidity = (data['turbidity'] as num?)?.toDouble() ?? 0.0;
            _waterLevel = (data['water_level'] as num?)?.toDouble() ?? 0.0;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_limitsLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF10132A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1E2247),
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF10132A),
      body: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 2.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Overall Status: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: _getOverallStatus(),
                      style: TextStyle(
                        color: _getOverallStatus() == 'Good'
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSensorCard('Temperature', _temperature, '°C',
                    'temperature', Icons.thermostat),
                _buildSensorCard(
                    'pH Level', _ph, '', 'ph_level', Icons.science),
                _buildSensorCard('Turbidity', _turbidity, 'NTU', 'turbidity',
                    Icons.water_drop),
                _buildSensorCard('Water Level', _waterLevel, '%',
                    'water_level', Icons.waves),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E325A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text(
                            'Warning',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        '• Keep the sensors clean and free from debris.\n'
                        '• Ensure the device is properly powered and connected.\n'
                        '• Monitor the app for alerts on unsafe water conditions.\n'
                        '• Take immediate action if levels are unsafe.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2247),
      ),
      child: const SafeArea(
        child: Center(
          child: Text(
            'Sensor Dashboard',
            style: TextStyle(
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

  Widget _buildSensorCard(
      String title, double value, String unit, String dataKey, IconData icon) {
    // Map dashboard IDs to Firestore field names
    final firestoreFieldName = {
          'temperature': 'temp',
          'ph_level': 'ph',
          'turbidity': 'turbidity',
          'water_level': 'water_level',
        }[dataKey] ??
        dataKey;

    final limits = sensorLimits[dataKey] ??
        {'min': 0.0, 'max': 100.0, 'minAlarm': 0.0, 'maxAlarm': 100.0};

    final min = limits['min']!;
    final max = limits['max']!;
    final normalizedValue = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorDetailPage(
              sensorName: title,
              unit: unit,
              minValue: limits['min']!,
              maxValue: limits['max']!,
              minAlarm: limits['minAlarm']!,
              maxAlarm: limits['maxAlarm']!,
              sensorId: firestoreFieldName, // Use the mapped field name
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E2247),
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3A3F71),
                    child: Icon(icon, color: const Color(0xFFB5C0F9)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${value.toStringAsFixed(2)}$unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getValueColor(normalizedValue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: normalizedValue,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF2E325A),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getValueColor(normalizedValue),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$min$unit',
                      style: const TextStyle(color: Colors.white70)),
                  Text('$max$unit',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getValueColor(double normalizedValue) {
    return Color.lerp(Colors.greenAccent, Colors.redAccent, normalizedValue)!;
  }

  String _getOverallStatus() {
    final checks = [
      (_temperature > sensorLimits['temperature']!['minAlarm']! &&
          _temperature < sensorLimits['temperature']!['maxAlarm']!),
      (_ph > sensorLimits['ph_level']!['minAlarm']! &&
          _ph < sensorLimits['ph_level']!['maxAlarm']!),
      (_turbidity > sensorLimits['turbidity']!['minAlarm']! &&
          _turbidity < sensorLimits['turbidity']!['maxAlarm']!),
      (_waterLevel > sensorLimits['water_level']!['minAlarm']! &&
          _waterLevel < sensorLimits['water_level']!['maxAlarm']!),
    ];

    final allGood = checks.every((check) => check);
    return allGood ? 'Good' : 'Alert';
  }
}
