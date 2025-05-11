import 'package:flutter/material.dart';
import 'dart:math';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  String? selectedSensor = 'Temperature';
  String? selectedTimePeriod = 'Day';
  
  // Mock data - replace with your actual data
  final Map<String, Map<String, List<SensorData>>> sensorData = {
    'Temperature': {
      'Hour': [
        SensorData(time: '00:00', value: 22.4),
        SensorData(time: '01:00', value: 22.1),
        SensorData(time: '02:00', value: 21.8),
        SensorData(time: '03:00', value: 21.5),
        SensorData(time: '04:00', value: 21.3),
        SensorData(time: '05:00', value: 21.6),
        SensorData(time: '06:00', value: 22.0),
        SensorData(time: '07:00', value: 22.8),
        SensorData(time: '08:00', value: 23.5),
        SensorData(time: '09:00', value: 24.2),
        SensorData(time: '10:00', value: 24.8),
        SensorData(time: '11:00', value: 25.1),
      ],
      'Day': List.generate(24, (i) => SensorData(time: '$i:00', value: 20 + (i/24)*8 + (Random().nextDouble()*2-1))),
      'Week': List.generate(7, (i) => SensorData(time: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], value: 18 + i + (Random().nextDouble()*3-1.5))),
      'Month': List.generate(30, (i) => SensorData(time: '${i+1}', value: 15 + (i/30)*12 + (Random().nextDouble()*4-2))),
    },
    'pH Level': {
      'Hour': [
        SensorData(time: '00:00', value: 7.2),
        SensorData(time: '01:00', value: 7.1),
        SensorData(time: '02:00', value: 7.0),
        SensorData(time: '03:00', value: 6.9),
        SensorData(time: '04:00', value: 6.8),
        SensorData(time: '05:00', value: 6.9),
        SensorData(time: '06:00', value: 7.0),
        SensorData(time: '07:00', value: 7.1),
        SensorData(time: '08:00', value: 7.2),
        SensorData(time: '09:00', value: 7.3),
        SensorData(time: '10:00', value: 7.4),
        SensorData(time: '11:00', value: 7.5),
      ],
      'Day': List.generate(24, (i) => SensorData(time: '$i:00', value: 6.5 + (i/24)*1.5 + (Random().nextDouble()*0.3-0.15))),
      'Week': List.generate(7, (i) => SensorData(time: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], value: 6.8 + (i*0.1) + (Random().nextDouble()*0.4-0.2))),
      'Month': List.generate(30, (i) => SensorData(time: '${i+1}', value: 6.5 + (i/30)*1.8 + (Random().nextDouble()*0.5-0.25))),
    },
    'Turbidity': {
      'Hour': List.generate(12, (i) => SensorData(time: '${i*2}:00', value: 5 + (i/12)*15 + (Random().nextDouble()*3-1.5))),
      'Day': List.generate(24, (i) => SensorData(time: '$i:00', value: 5 + (i/24)*20 + (Random().nextDouble()*4-2))),
      'Week': List.generate(7, (i) => SensorData(time: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], value: 5 + i*3 + (Random().nextDouble()*5-2.5))),
      'Month': List.generate(30, (i) => SensorData(time: '${i+1}', value: 5 + (i/30)*25 + (Random().nextDouble()*6-3))),
    },
    'Water Level': {
      'Hour': List.generate(12, (i) => SensorData(time: '${i*2}:00', value: 50 + (i/12)*30 + (Random().nextDouble()*5-2.5))),
      'Day': List.generate(24, (i) => SensorData(time: '$i:00', value: 50 + (i/24)*40 + (Random().nextDouble()*6-3))),
      'Week': List.generate(7, (i) => SensorData(time: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][i], value: 50 + i*7 + (Random().nextDouble()*8-4))),
      'Month': List.generate(30, (i) => SensorData(time: '${i+1}', value: 50 + (i/30)*60 + (Random().nextDouble()*10-5))),
    },
  };

  List<String> sensorOptions = ['Temperature', 'pH Level', 'Turbidity', 'Water Level'];
  List<String> timePeriodOptions = ['Hour', 'Day', 'Week', 'Month'];

  @override
  Widget build(BuildContext context) {
    final currentData = sensorData[selectedSensor]?[selectedTimePeriod] ?? [];
    final stats = _calculateStats(currentData);

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
                        onChanged: (value) => setState(() => selectedSensor = value),
                        hint: 'Select Sensor',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: selectedTimePeriod,
                        items: timePeriodOptions,
                        onChanged: (value) => setState(() => selectedTimePeriod = value),
                        hint: 'Select Time Period',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
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
                if (stats['avg'] != null) _buildRecommendations(stats['avg']!, selectedSensor!),
              ],
            ),
          ),
        ],
      ),
    );
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
      series: <LineSeries<SensorData, String>>[ // Changed this line
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
        statusColor = Colors.blue;
      } else if (avgValue > 30) {
        recommendation = 'Water is too warm. Consider cooling.';
        statusColor = Colors.red;
      } else {
        recommendation = 'Temperature is within optimal range.';
        statusColor = Colors.green;
      }
    } else if (sensor == 'pH Level') {
      if (avgValue < 6.5) {
        recommendation = 'Water is too acidic. Needs treatment.';
        statusColor = Colors.orange;
      } else if (avgValue > 8.5) {
        recommendation = 'Water is too alkaline. Needs treatment.';
        statusColor = Colors.orange;
      } else {
        recommendation = 'pH level is balanced. Good condition.';
        statusColor = Colors.green;
      }
    } else if (sensor == 'Turbidity') {
      if (avgValue > 10) {
        recommendation = 'High turbidity detected. Filtration needed.';
        statusColor = Colors.orange;
      } else {
        recommendation = 'Water clarity is good.';
        statusColor = Colors.green;
      }
    } else if (sensor == 'Water Level') {
      if (avgValue < 30) {
        recommendation = 'Water level is low. Consider refilling.';
        statusColor = Colors.orange;
      } else if (avgValue > 90) {
        recommendation = 'Water level is too high. Risk of overflow.';
        statusColor = Colors.red;
      } else {
        recommendation = 'Water level is optimal.';
        statusColor = Colors.green;
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
            statusColor == Colors.green ? Icons.check_circle : Icons.warning,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
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

  SensorData({required this.time, required this.value});
}