import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

class Run5kScreen extends StatefulWidget {
  const Run5kScreen({super.key});

  @override
  State<Run5kScreen> createState() => _Run5kScreenState();
}

class _Run5kScreenState extends State<Run5kScreen> {
  bool _running = false;
  DateTime? _startTime;
  Duration? _elapsed;
  double _distanceKm = 0.0;
  StreamSubscription<Position>? _posSub;
  final List<LatLng> _track = [];
  final MapController _mapController = MapController();

  void _start() {
    setState(() {
      _running = true;
      _startTime = DateTime.now();
      _elapsed = null;
      _distanceKm = 0.0;
    });
    _startGps();
  }

  void _stop() {
    if (_startTime == null) return;
    _posSub?.cancel();
    _posSub = null;
    setState(() {
      _running = false;
      _elapsed = DateTime.now().difference(_startTime!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('5 km Run', style: GoogleFonts.urbanist(fontWeight: FontWeight.w600)),
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
              _summaryCard(),
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
          _bullet('Choose a measured 5.00 km route or 12.5 laps on a 400 m track.'),
          _bullet('Warm up 5–10 minutes. Hydrate; avoid extreme weather.'),
          _bullet('Pace evenly. Aim for negative split (second half faster).'),
          _bullet('Stop the timer exactly at 5.00 km. Record average pace and splits.'),
          const SizedBox(height: 12),
          Text('Upcoming: GPS tracking', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          _bullet('We’ll add GPS distance and pace metrics with smoothing.'),
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
        children: [
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
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _track.isNotEmpty ? _track.last : const LatLng(0, 0),
                  initialZoom: _track.isNotEmpty ? 16 : 2,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.coach_ai_v2',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _track, color: Colors.blue, strokeWidth: 4),
                    ],
                  ),
                  if (_track.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _track.last,
                          width: 20,
                          height: 20,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final seconds = _elapsed!.inMilliseconds / 1000.0;
    final paceMinPerKm = _distanceKm > 0 ? (seconds / 60.0) / _distanceKm : 0.0;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Elapsed Time', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${seconds.toStringAsFixed(1)} s', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${_distanceKm.toStringAsFixed(2)} km', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Avg Pace', style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(paceMinPerKm > 0 ? '${paceMinPerKm.toStringAsFixed(2)} min/km' : '—', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
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

  Future<void> _startGps() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    final service = await Geolocator.isLocationServiceEnabled();
    if (!service) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable location services')));
      }
      return;
    }

    _track.clear();
    Position? last;
    
    // Get initial position to center map
    try {
      final initialPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final initialLatLng = LatLng(initialPos.latitude, initialPos.longitude);
      _track.add(initialLatLng);
      _mapController.move(initialLatLng, 16);
    } catch (e) {
      // Continue without initial position
    }
    
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best, 
        distanceFilter: 3,
        timeLimit: Duration(seconds: 5),
      ),
    ).listen((pos) {
      final current = LatLng(pos.latitude, pos.longitude);
      
      // Add to track
      _track.add(current);
      
      // Update distance if we have a previous position
      if (last != null) {
        final d = Geolocator.distanceBetween(
          last!.latitude, 
          last!.longitude, 
          pos.latitude, 
          pos.longitude
        );
        _distanceKm += d / 1000.0;
        
        // Auto-stop at 5.00 km
        if (_distanceKm >= 5.0) {
          _stop();
          return;
        }
      }
      
      // Center map on current position
      _mapController.move(current, 16);
      
      last = pos;
      setState(() {});
    }, onError: (error) {
      print('GPS Error: $error');
    });
  }
}



