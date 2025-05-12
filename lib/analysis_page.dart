import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String? selectedSensor = 'Temperature';
  String? selectedTimePeriod = 'Day';
  bool isLoading = false;
  String errorMessage = '';

  List<String> sensorOptions = ['Temperature', 'pH Level', 'Turbidity', 'Water Level'];
  List<String> timePeriodOptions = ['Hour', 'Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10132A),
      body: Column(
        children: [
          _buildHeader('Analysis'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sensor and Time Period Selectors
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: selectedSensor,
                        items: sensorOptions,
                        onChanged: (value) => setState(() {
                          selectedSensor = value;
                          _fetchData();
                        }),
                        hint: 'Select Sensor',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: selectedTimePeriod,
                        items: timePeriodOptions,
                        onChanged: (value) => setState(() {
                          selectedTimePeriod = value;
                          _fetchData();
                        }),
                        hint: 'Select Time Period',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (isLoading)
                  const Center(child: CircularProgressIndicator()),
                
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                
                // Data display
                StreamBuilder<List<SensorData>>(
                  stream: _getSensorDataStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No data available', style: TextStyle(color: Colors.white)));
                    }
                    
                    final currentData = snapshot.data!;
                    final stats = _calculateStats(currentData);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Statistics Cards
                        _buildStatisticsCards(stats),
                        const SizedBox(height: 24),
                        
                        // Chart Title
                        Text(
                          '$selectedSensor Trend ($selectedTimePeriod)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Chart Container
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2247),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          height: 300,
                          child: _buildChart(currentData),
                        ),
                        
                        // Additional Recommendations
                        if (stats['avg'] != null) 
                          _buildRecommendations(stats['avg']!, selectedSensor!),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<SensorData>> _getSensorDataStream() {
    final now = DateTime.now();
    DateTime startDate;
    
    switch (selectedTimePeriod) {
      case 'Hour':
        startDate = now.subtract(const Duration(hours: 1));
        break;
      case 'Day':
        startDate = now.subtract(const Duration(days: 1));
        break;
      case 'Week':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        startDate = now.subtract(const Duration(days: 30));
        break;
      default:
        startDate = now.subtract(const Duration(days: 1));
    }
    
    // Convert sensor name to match your Firebase document ID format
    final sensorName = selectedSensor?.toLowerCase().replaceAll(' ', '_') ?? '';
    
    return FirebaseFirestore.instance
        .collection('sensor_readings')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      // Filter documents for the selected sensor and process data
      return snapshot.docs
          .where((doc) => doc.id.endsWith(sensorName))
          .map((doc) {
            final data = doc.data();
            final timestamp = (data['timestamp'] as Timestamp).toDate();
            
            // Format time based on selected period
            String timeLabel;
            if (selectedTimePeriod == 'Hour' || selectedTimePeriod == 'Day') {
              timeLabel = DateFormat('HH:mm').format(timestamp);
            } else if (selectedTimePeriod == 'Week') {
              timeLabel = DateFormat('EEE').format(timestamp);
            } else {
              timeLabel = DateFormat('d').format(timestamp);
            }
            
            return SensorData(
              time: timeLabel,
              value: (data['value'] as num).toDouble(),
              timestamp: timestamp,
            );
          })
          .toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    
    try {
      // The StreamBuilder will handle the data loading
      await Future.delayed(const Duration(milliseconds: 100)); // Small delay for smoother UI
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load data: $e';
      });
    }
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2247),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<String>(
        value: value,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: const Color(0xFF1E2247),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          hint,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, double?> stats) {
    return Row(
      children: [
        _buildStatCard('Min', stats['min']?.toStringAsFixed(2) ?? '--', Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Avg', stats['avg']?.toStringAsFixed(2) ?? '--', Colors.green),
        const SizedBox(width: 12),
        _buildStatCard('Max', stats['max']?.toStringAsFixed(2) ?? '--', Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2247),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<SensorData> data) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: CategoryAxis(
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorGridLines: MajorGridLines(color: Colors.white.withOpacity(0.1)),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      series: <LineSeries<SensorData, String>>[
        LineSeries<SensorData, String>(
          dataSource: data,
          xValueMapper: (SensorData data, _) => data.time,
          yValueMapper: (SensorData data, _) => data.value,
          color: const Color(0xFF00E5FF),
          width: 3,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: Colors.white,
            color: Color(0xFF00E5FF),
          ),
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: selectedSensor,
        format: 'point.x : point.y',
        color: const Color(0xFF1E2247),
        textStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildRecommendations(double avgValue, String sensor) {
    String recommendation = '';
    Color statusColor = Colors.grey;

    if (sensor == 'Temperature') {
      if (avgValue < 10) {
        recommendation = 'Water is too cold. Consider heating.';
        statusColor = Colors.blueAccent;
      } else if (avgValue > 30) {
        recommendation = 'Water is too warm. Consider cooling.';
        statusColor = Colors.redAccent;
      } else {
        recommendation = 'Temperature is within optimal range.';
        statusColor = Colors.greenAccent;
      }
    } else if (sensor == 'pH Level') {
      if (avgValue < 6.5) {
        recommendation = 'Water is too acidic. Needs treatment.';
        statusColor = Colors.orangeAccent;
      } else if (avgValue > 8.5) {
        recommendation = 'Water is too alkaline. Needs treatment.';
        statusColor = Colors.orangeAccent;
      } else {
        recommendation = 'pH level is balanced. Good condition.';
        statusColor = Colors.greenAccent;
      }
    } else if (sensor == 'Turbidity') {
      if (avgValue > 10) {
        recommendation = 'High turbidity detected. Filtration needed.';
        statusColor = Colors.orangeAccent;
      } else {
        recommendation = 'Water clarity is good.';
        statusColor = Colors.greenAccent;
      }
    } else if (sensor == 'Water Level') {
      if (avgValue < 30) {
        recommendation = 'Water level is low. Consider refilling.';
        statusColor = Colors.orangeAccent;
      } else if (avgValue > 90) {
        recommendation = 'Water level is too high. Risk of overflow.';
        statusColor = Colors.redAccent;
      } else {
        recommendation = 'Water level is optimal.';
        statusColor = Colors.greenAccent;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2247),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusColor == Colors.greenAccent ? Icons.check_circle : Icons.warning,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double?> _calculateStats(List<SensorData> data) {
    if (data.isEmpty) return {'min': null, 'max': null, 'avg': null};

    double min = data.first.value;
    double max = data.first.value;
    double sum = 0;

    for (var item in data) {
      if (item.value < min) min = item.value;
      if (item.value > max) max = item.value;
      sum += item.value;
    }

    return {
      'min': min,
      'max': max,
      'avg': sum / data.length,
    };
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
}

class SensorData {
  final String time;
  final double value;
  final DateTime timestamp;

  SensorData({
    required this.time,
    required this.value,
    required this.timestamp,
  });
}