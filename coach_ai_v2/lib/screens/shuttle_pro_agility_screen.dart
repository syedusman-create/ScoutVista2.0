import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

class ShuttleProAgilityScreen extends StatefulWidget {
  const ShuttleProAgilityScreen({super.key});

  @override
  State<ShuttleProAgilityScreen> createState() => _ShuttleProAgilityScreenState();
}

class _ShuttleProAgilityScreenState extends State<ShuttleProAgilityScreen> {
  bool _running = false;
  DateTime? _startTime;
  Duration? _elapsed;
  bool _autoMode = true;
  StreamSubscription<UserAccelerometerEvent>? _imuSub;
  double _lastAx = 0.0;
  int _segmentsCompleted = 0; // after two turns, finish on stop
  DateTime? _lastTurnAt;
  final int _minMsBetweenTurns = 300;
  final double _startThreshold = 1.5; // m/s^2
  final double _turnThreshold = 2.0;  // m/s^2 peak before sign flip
  final double _stopRmsThreshold = 0.35; // m/s^2
  final int _stopHoldMs = 350;
  final List<double> _rmsWindow = [];
  final int _rmsWindowLen = 12; // ~240ms at 50Hz
  DateTime? _belowStopSince;
  List<Duration> _splits = [];

  void _start() {
    setState(() {
      _running = true;
      _startTime = DateTime.now();
      _elapsed = null;
      _segmentsCompleted = 0;
      _splits = [];
      _lastTurnAt = null;
      _belowStopSince = null;
    });
    if (_autoMode) _startImu();
  }

  void _stop() {
    if (_startTime == null) return;
    _disposeImu();
    setState(() {
      _running = false;
      _elapsed = DateTime.now().difference(_startTime!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('5-10-5 Pro Agility', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _guideCard(),
            const SizedBox(height: 16),
            _controlsCard(),
            if (_elapsed != null) ...[
              const SizedBox(height: 16),
              _resultCard(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _guideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Setup & Instructions', style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _bullet('Place 3 cones in a straight line, exactly 5 yards (4.57 m) apart.'),
          _bullet('Start straddling the middle cone with one hand touching the line.'),
          _bullet('On “Go”: sprint 5y to one side (touch), 10y to the far side (touch), 5y back to middle.'),
          _bullet('Plant outside foot at each turn, keep hips low and chest over knees.'),
          _bullet('Time stops when torso crosses the middle line at the end.'),
          const SizedBox(height: 12),
          Text('Tips for Accuracy', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullet('Use a measured tape for 5-yard spacing.'),
          _bullet('Run on a flat, non-slippery surface; wear grippy shoes.'),
          _bullet('Have a partner operate Start/Stop or use an external timing gate if available.'),
        ],
      ),
    );
  }

  Widget _controlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: _autoMode,
                onChanged: _running ? null : (v) => setState(() => _autoMode = v),
              ),
              const SizedBox(width: 8),
              Text(_autoMode ? 'Auto (IMU) timing' : 'Manual timing', style: GoogleFonts.urbanist(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? null : _start,
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _running ? _stop : null,
                  child: const Text('Stop'),
                ),
              ),
            ],
          ),
          if (_splits.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Splits', style: GoogleFonts.urbanist(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (int i = 0; i < _splits.length; i++)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Segment ${i + 1}', style: GoogleFonts.urbanist(fontSize: 14)),
                  Text('${(_splits[i].inMilliseconds / 1000.0).toStringAsFixed(2)} s', style: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard() {
    final seconds = _elapsed!.inMilliseconds / 1000.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Time', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('${seconds.toStringAsFixed(2)} s', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text, style: GoogleFonts.urbanist(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }

  void _startImu() {
    _disposeImu();
    _imuSub = userAccelerometerEvents.listen((e) {
      if (!_running || _startTime == null) return;
      final ax = e.x; // assume phone on waistband, screen facing out

      // Start gate: first strong acceleration
      if (_segmentsCompleted == 0 && _elapsed == null) {
        final sinceStart = DateTime.now().difference(_startTime!);
        // ensure we truly started moving
        if (ax.abs() > _startThreshold) {
          // Start already set at _startTime
        }
      }

      // Detect turns by sign flip with peak magnitude
      final signChanged = (_lastAx <= 0 && ax > 0) || (_lastAx >= 0 && ax < 0);
      final now = DateTime.now();
      if (signChanged && (_lastTurnAt == null || now.difference(_lastTurnAt!).inMilliseconds > _minMsBetweenTurns)) {
        if (ax.abs() > _turnThreshold) {
          _lastTurnAt = now;
          _segmentsCompleted++;
          _splits.add(now.difference(_startTime!));
          setState(() {});
        }
      }

      // Rolling RMS for stop detection after two turns
      final mag = ax.abs();
      _rmsWindow.add(mag);
      if (_rmsWindow.length > _rmsWindowLen) _rmsWindow.removeAt(0);
      final rms = _rmsWindow.isEmpty
          ? 0.0
          : ( _rmsWindow.map((v) => v * v).reduce((a,b)=>a+b) / _rmsWindow.length ).sqrt();

      if (_segmentsCompleted >= 2) {
        if (rms < _stopRmsThreshold) {
          _belowStopSince ??= now;
          if (now.difference(_belowStopSince!).inMilliseconds > _stopHoldMs) {
            _stop();
          }
        } else {
          _belowStopSince = null;
        }
      }

      _lastAx = ax;
    });
  }

  void _disposeImu() {
    _imuSub?.cancel();
    _imuSub = null;
    _rmsWindow.clear();
  }

}

extension _Sqrt on double {
  double sqrt() => this <= 0 ? 0.0 : (this).toDouble()._sqrtNewton();
  double _sqrtNewton() {
    double x = this;
    double r = x;
    for (int i = 0; i < 6; i++) {
      r = 0.5 * (r + x / r);
    }
    return r.isFinite ? r : 0.0;
  }
}

