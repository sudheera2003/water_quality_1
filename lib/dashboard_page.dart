import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sensor_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DatabaseReference _databaseRef;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _temperature = 0.0;
  double _ph = 0.0;
  double _turbidity = 0.0;
  double _waterLevel = 0.0;

  Map<String, Map<String, double>> sensorLimits = {
    'temperature': {'min': 0, 'max': 50},
    'ph level': {'min': 0, 'max': 14},
    'turbidity': {'min': 0, 'max': 100},
    'water level': {'min': 0, 'max': 200},
  };

  bool _limitsLoaded = false;

  @override
  void initState() {
    super.initState();
    final app = Firebase.app('myCustomApp');
    _databaseRef = FirebaseDatabase.instanceFor(app: app).ref();

    _fetchSensorLimits().then((_) {
      setState(() {
        _limitsLoaded = true;
      });
    });

    _setupRealtimeListener();
  }

  Future<void> _fetchSensorLimits() async {
    final sensors = ['temperature', 'ph level', 'turbidity', 'water level'];
    for (var sensor in sensors) {
      final doc = await _firestore.collection('sensorSettings').doc(sensor).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          sensorLimits[sensor] = {
            'min': (data['min'] ?? 0).toDouble(),
            'max': (data['max'] ?? 100).toDouble(),
          };
        }
      }
    }
  }

  void _setupRealtimeListener() {
    _databaseRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data != null && mounted) {
        Map<dynamic, dynamic> sensorData;
        if (data is Map) {
          sensorData = data;
        } else {
          debugPrint('Unexpected data format: ${data.runtimeType}');
          return;
        }

        setState(() {
          _temperature = (sensorData['temperature'] ?? 0.0).toDouble();
          _ph = (sensorData['ph level'] ?? 0.0).toDouble();
          _turbidity = (sensorData['turbidity'] ?? 0.0).toDouble();
          _waterLevel = (sensorData['water level'] ?? 0.0).toDouble();
        });
      }
    }, onError: (error) {
      debugPrint('Error reading data: $error');
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
                      text: 'Good',
                      style: TextStyle(
                        color: Colors.greenAccent,
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
                _buildSensorCard('Temperature', _temperature, '°C', 'temperature', Icons.thermostat),
                _buildSensorCard('pH Level', _ph, '', 'ph level', Icons.science),
                _buildSensorCard('Turbidity', _turbidity, 'NTU', 'turbidity', Icons.water_drop),
                _buildSensorCard('Water Level', _waterLevel, 'cm', 'water level', Icons.waves),

                // Warning box
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
                    children: [
                      Row(
                        children: const [
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
                      const SizedBox(height: 10),
                      const Text(
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E2247),
      ),
      child: SafeArea(
        child: Center(
          child: Text(
            'Sensor Dashboard',
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

  Widget _buildSensorCard(String title, double value, String unit, String dataKey, IconData icon) {
    final min = sensorLimits[dataKey]?['min'] ?? 0;
    final max = sensorLimits[dataKey]?['max'] ?? 100;
    final normalizedValue = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SensorDetailPage(
              sensorName: title,
              unit: unit,
              minValue: min,
              maxValue: max,
              databaseRef: _databaseRef,
              dataKey: dataKey,
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
                  Text('$min$unit', style: const TextStyle(color: Colors.white70)),
                  Text('$max$unit', style: const TextStyle(color: Colors.white70)),
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
}
