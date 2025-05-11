import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauges;
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'dart:ui';

class SensorDetailPage extends StatefulWidget {
  final String sensorName;
  final String unit;
  final double minValue;
  final double maxValue;
  final double minAlarm;
  final double maxAlarm;
  final String sensorId;

  const SensorDetailPage({
    super.key,
    required this.sensorName,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.minAlarm,
    required this.maxAlarm,
    required this.sensorId,
  });

  @override
  State<SensorDetailPage> createState() => _SensorDetailPageState();
}

class _SensorDetailPageState extends State<SensorDetailPage> {
  double? _currentValue;
  StreamSubscription<DocumentSnapshot>? _sensorSubscription;
  bool _isDataLoaded = false;
  List<SensorDataPoint> _dataPoints = [];

  @override
  void initState() {
    super.initState();
    _listenToSensorValue();
  }

  void _listenToSensorValue() {
    _sensorSubscription = FirebaseFirestore.instance
        .collection('sensorReadings')
        .doc('latest')
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      final dynamic rawValue = data[widget.sensorId];
      final double value = (rawValue is int) ? rawValue.toDouble() : rawValue;

      if (mounted) {
        setState(() {
          _currentValue = value;
          _isDataLoaded = true;
          _dataPoints.add(SensorDataPoint(DateTime.now(), value));
          if (_dataPoints.length > 100) _dataPoints.removeAt(0);
        });
      }
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Color _getStatusColor(double? value) {
    if (value == null) return Colors.white;
    if (value <= widget.minAlarm || value >= widget.maxAlarm) {
      return Colors.redAccent;
    }
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10132A),
      appBar: AppBar(
        title: Text('${widget.sensorName} Overview', 
            style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E2247),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: (_isDataLoaded)
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCircularGauge(),
                    const SizedBox(height: 20),
                    _buildCurrentValueDisplay(),
                    const SizedBox(height: 20),
                    _buildAlarmingValues(),
                    const SizedBox(height: 20),
                    _buildLineChart(),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFB5C0F9),
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentValueDisplay() {
    final iconColor = _getStatusColor(_currentValue);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1E2247),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF3A3F71),
              child: Icon(Icons.sensors, color: iconColor),
            ),
            const SizedBox(width: 12),
            Text(
              'Current Value: ${_currentValue?.toStringAsFixed(2) ?? '--'} ${widget.unit}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Changed to white
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmingValues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Alarming Values",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAlarmInfo(
              'Minimum: ${widget.minAlarm.toStringAsFixed(2)}',
              Icons.trending_down, 
               Colors.greenAccent,
            ),
            _buildAlarmInfo(
              'Maximum: ${widget.maxAlarm.toStringAsFixed(2)}',
              Icons.trending_up, 
              Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlarmInfo(String label, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2E325A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildCircularGauge() {
  return SizedBox(
    height: 250,
    child: gauges.SfRadialGauge(
      enableLoadingAnimation: true,
      title: gauges.GaugeTitle(
        text: '${widget.sensorName} Reading',
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      axes: <gauges.RadialAxis>[
        gauges.RadialAxis(
          minimum: widget.minValue,
          maximum: widget.maxValue,
          showAxisLine: true,
          showLabels: true,
          showTicks: true,
          axisLabelStyle: const gauges.GaugeTextStyle(color: Colors.white),
          ranges: [
            gauges.GaugeRange(
              startValue: widget.minValue,
              endValue: widget.minAlarm,
              color: Colors.transparent,
            ),
            gauges.GaugeRange(
              startValue: widget.minAlarm,
              endValue: widget.maxAlarm,
              color: Colors.transparent,
            ),
            gauges.GaugeRange(
              startValue: widget.maxAlarm,
              endValue: widget.maxValue,
              color: Colors.transparent,
            ),
          ],
          pointers: <gauges.GaugePointer>[
            gauges.NeedlePointer(
              value: _currentValue ?? widget.minValue,
              needleColor: Colors.redAccent,
              needleLength: 0.55,
              enableAnimation: true,
              animationDuration: 1000,
              animationType: gauges.AnimationType.ease,
              knobStyle: const gauges.KnobStyle(
                knobRadius: 0.1,
                sizeUnit: gauges.GaugeSizeUnit.factor,
                color: Colors.redAccent,
              ),
            ),
          ],
          axisLineStyle: gauges.AxisLineStyle(
            thickness: 15,
            gradient: const SweepGradient(
              colors: [Colors.green, Colors.yellow, Colors.redAccent],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          annotations: <gauges.GaugeAnnotation>[
            gauges.GaugeAnnotation(
              widget: Text(
                '${_currentValue?.toStringAsFixed(2) ?? widget.minValue.toStringAsFixed(2)} ${widget.unit}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              angle: 90,
              positionFactor: 0.8,
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildLineChart() {
    return SizedBox(
      height: 250,
      child: Card(
        color: const Color(0xFF1E2247),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: charts.SfCartesianChart(
            title: charts.ChartTitle(
              text: '${widget.sensorName} History',
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            primaryXAxis: charts.DateTimeAxis(
              intervalType: charts.DateTimeIntervalType.seconds,
              labelStyle: const TextStyle(color: Colors.white70),
              axisLine: const charts.AxisLine(color: Colors.white70),
              majorGridLines: const charts.MajorGridLines(color: Colors.transparent),
            ),
            primaryYAxis: charts.NumericAxis(
              minimum: widget.minValue,
              maximum: widget.maxValue,
              labelStyle: const TextStyle(color: Colors.white70),
              axisLine: const charts.AxisLine(color: Colors.white70),
              majorGridLines: const charts.MajorGridLines(color: Colors.white10),
            ),
            series: <charts.LineSeries<SensorDataPoint, DateTime>>[
              charts.LineSeries<SensorDataPoint, DateTime>(
                dataSource: _dataPoints,
                xValueMapper: (SensorDataPoint point, _) => point.time,
                yValueMapper: (SensorDataPoint point, _) => point.value,
                color: Colors.redAccent,
                width: 2,
                markerSettings: const charts.MarkerSettings(
                  isVisible: true,
                  shape: charts.DataMarkerType.circle,
                  borderWidth: 2,
                  borderColor: Colors.redAccent,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorDataPoint {
  final DateTime time;
  final double value;

  SensorDataPoint(this.time, this.value);
}