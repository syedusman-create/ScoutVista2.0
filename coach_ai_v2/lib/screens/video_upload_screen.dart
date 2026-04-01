import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Using ML Kit landmarks + heuristics
import '../utils/ai/video_processor.dart';
import '../utils/ai/mlkit/pose_extractor.dart';
import '../utils/ai/core/pose_types.dart';
import '../utils/ai/heuristics/landmark_exercises.dart';
import '../utils/ai/heuristics/landmark_shuttle.dart';
import '../utils/logger.dart';
import '../models/workout_session.dart';
import '../services/profile_service.dart';
import 'results_screen.dart';

class VideoUploadScreen extends StatefulWidget {
  final String exerciseType;
  
  const VideoUploadScreen({
    super.key,
    required this.exerciseType,
  });

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isProcessing = false;
  bool _isUploading = false;
  double _processingProgress = 0.0;
  String _processingStatus = '';

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        
        // Check file size (limit to 50MB for free tier optimization)
        final fileSize = await file.length();
        const maxSize = 50 * 1024 * 1024; // 50MB
        
        if (fileSize > maxSize) {
          _showErrorDialog(
            'Video file is too large. Please select a video smaller than 50MB to stay within Firebase free tier limits.'
          );
          return;
        }
        
        setState(() {
          _selectedVideo = file;
        });
        
        _initializeVideoPlayer();
        
        // Show file size info
        final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video selected: ${sizeInMB}MB'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error picking video: $e');
    }
  }

  void _initializeVideoPlayer() {
    if (_selectedVideo != null) {
      _videoController = VideoPlayerController.file(_selectedVideo!);
      _videoController!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  Future<void> _processVideo() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isProcessing = true;
      _processingProgress = 0.0;
      _processingStatus = 'Initializing video analysis...';
    });

    try {
      // Diagnostics counters
      int framesExtracted = 0;
      int poseDetectionsSucceeded = 0;
      int poseDetectionsFailed = 0;
      int formAnalysesSucceeded = 0;
      int formAnalysesFailed = 0;
      String repCountSource = 'unknown';
      // Initialize video processor
      final videoProcessor = VideoProcessor();
      
      // Update progress
      setState(() {
        _processingProgress = 0.2;
        _processingStatus = 'Extracting video frames...';
      });

      // Extract frames from video
      final frames = await videoProcessor.extractFrames(_selectedVideo!);
      framesExtracted = frames.length;
      
      VideoLogger.frameExtraction(frames.length, frames.length);
      
      if (frames.isEmpty) {
        Logger.error('No frames extracted from video', tag: 'VIDEO_UPLOAD');
        throw Exception('No frames could be extracted from the video. Please try a different video.');
      }
      
      setState(() {
        _processingProgress = 0.6;
        _processingStatus = 'Detecting poses (ML Kit) & running heuristics...';
      });

      final extractor = MlkitPoseExtractor();
      final List<FrameLandmarks> landmarkFrames = [];
      for (int i = 0; i < frames.length; i++) {
        final lm = await extractor.extract(frames[i]);
        landmarkFrames.add(FrameLandmarks(frameIndex: i, landmarks: lm));
        
        // Debug logging for pose detection
        if (lm.isNotEmpty) {
          poseDetectionsSucceeded++;
          if (poseDetectionsSucceeded <= 3) {
            Logger.info('🎯 ML Kit pose detected', tag: 'POSE_DETECTION', 
              data: {'frame': i, 'landmarkCount': lm.length});
          }
        } else {
          poseDetectionsFailed++;
          if (poseDetectionsFailed <= 3) {
            Logger.warning('❌ ML Kit pose detection failed', tag: 'POSE_DETECTION', 
              data: {'frame': i});
          }
        }
        
        if (i % 5 == 0) {
          setState(() {
            _processingProgress = 0.6 + 0.3 * (i / frames.length);
            _processingStatus = 'Processing frame ${i + 1}/${frames.length}...';
          });
        }
      }
      await extractor.close();

      // Landmark-driven heuristics with improved accuracy
      final List<List<PoseLandmarkLite>> lmSeq = landmarkFrames.map((f) => f.landmarks).toList();
      
      // Debug: Check landmark sequence before processing
      int framesWithLandmarks = lmSeq.where((frame) => frame.isNotEmpty).length;
      Logger.info('🔍 Pre-processing landmark analysis', tag: 'LANDMARK_DEBUG', 
        data: {
          'totalFrames': lmSeq.length, 
          'framesWithLandmarks': framesWithLandmarks,
          'exerciseType': widget.exerciseType,
          'poseDetectionsSucceeded': poseDetectionsSucceeded,
          'poseDetectionsFailed': poseDetectionsFailed
        });
      
      int repCount = 0;
      List<double> perFrameScores = [];
      List<RepDetectionEvent> repEvents = [];
      Map<String, dynamic>? shuttleReport;
      
            switch (widget.exerciseType) {
              case 'push_up':
          repCount = LandmarkPushUp.countReps(lmSeq);
          perFrameScores = LandmarkPushUp.frameScores(lmSeq);
          repEvents = LandmarkPushUp.getDetectionEvents();
                break;
              case 'pull_up':
          repCount = LandmarkPullUp.countReps(lmSeq);
          perFrameScores = LandmarkPullUp.frameScores(lmSeq);
          repEvents = LandmarkPullUp.getDetectionEvents();
                break;
              case 'squat':
          Logger.info('🏋️ About to call squat detection', tag: 'SQUAT_DEBUG', 
            data: {'framesWithLandmarks': framesWithLandmarks});
          repCount = LandmarkSquat.countReps(lmSeq);
          perFrameScores = LandmarkSquat.frameScores(lmSeq);
          repEvents = LandmarkSquat.getDetectionEvents();
          Logger.info('🏋️ Squat detection completed', tag: 'SQUAT_DEBUG', 
            data: {'repCount': repCount, 'events': repEvents.length});
                break;
              case 'shuttle_pro_agility':
          final calib = LandmarkShuttle.calibrate(lmSeq);
          final durationSec = _videoController?.value.duration.inSeconds.toDouble() ?? 0.0;
          final res = LandmarkShuttle.analyze(lmSeq, calib, durationSec);
          repCount = res.shuttles; // use shuttles as rep-like count
          perFrameScores = List<double>.filled(lmSeq.length, res.totalScore);
          shuttleReport = {
            'shuttles': res.shuttles,
            'speedScore': res.speedScore,
            'turnScore': res.turnScore,
            'straightnessScore': res.straightnessScore,
            'totalScore': res.totalScore,
            'leftBoundary': calib.leftBoundary,
            'rightBoundary': calib.rightBoundary,
          };
                break;
              default:
          repCount = LandmarkPushUp.countReps(lmSeq);
          perFrameScores = LandmarkPushUp.frameScores(lmSeq);
          repEvents = LandmarkPushUp.getDetectionEvents();
      }

      final List<Map<String, dynamic>> analysisResults = List.generate(perFrameScores.length, (i) => {
              'frame': i,
              'timestamp': (i / frames.length) * _videoController!.value.duration.inSeconds,
        'formScore': perFrameScores[i],
      });

      setState(() {
        _processingProgress = 0.8;
        _processingStatus = 'Counting repetitions...';
      });

      repCountSource = 'mlkit+landmark_heuristic';
        AILogger.repCounting(repCount, widget.exerciseType);
      Logger.info('Rep count from heuristic', tag: 'AI', data: {
          'totalReps': repCount,
          'framesAnalyzed': analysisResults.length,
        });

      setState(() {
        _processingProgress = 0.9;
        _processingStatus = 'Generating report...';
      });

      // Calculate overall metrics
      final double averageFormScore = analysisResults.isNotEmpty
          ? analysisResults.map((r) => r['formScore'] as double).reduce((a, b) => a + b) / analysisResults.length
          : 0.0;

      final report = {
        'exerciseType': widget.exerciseType,
        'totalReps': repCount,
        'averageFormScore': averageFormScore,
        'analysisResults': analysisResults,
        'repDetectionEvents': repEvents.map((e) => e.toJson()).toList(),
        'videoDuration': _videoController?.value.duration.inSeconds ?? 30,
        'timestamp': DateTime.now().toIso8601String(),
        if (shuttleReport != null) 'shuttleAnalysis': shuttleReport,
      };

      setState(() {
        _processingProgress = 1.0;
        _processingStatus = 'Analysis complete!';
      });

      // Upload summaries only (no video)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _saveAnalysisOnly(user, report);
          
          // Create workout session and update profile stats
          final session = WorkoutSession(
            id: '',
            userId: user.uid,
            exerciseType: widget.exerciseType,
            startTime: DateTime.now().subtract(Duration(seconds: _videoController?.value.duration.inSeconds ?? 30)),
            endTime: DateTime.now(),
            duration: Duration(seconds: _videoController?.value.duration.inSeconds ?? 30),
            results: report,
            metrics: _generateWorkoutMetrics(report),
            isPublic: true, // Default to public for now
            tags: [],
            sharedWith: [],
          );
          
          await ProfileService.updateStatsAfterWorkout(user.uid, session);
        } else {
          Logger.warning('No authenticated user - skipping Firestore save', tag: 'FIREBASE');
        }
      } catch (e) {
        Logger.warning('Firestore save failed - continuing with local results', tag: 'VIDEO_UPLOAD', data: {'error': e.toString()});
      }

      // End-of-pipeline diagnostic summary
      Logger.info('Pipeline diagnostic summary', tag: 'PIPELINE', data: {
        'exerciseType': widget.exerciseType,
        'framesExtracted': framesExtracted,
        'poseDetectionsSucceeded': 0,
        'poseDetectionsFailed': 0,
        'formAnalysesSucceeded': analysisResults.length,
        'formAnalysesFailed': 0,
        'analysisResultsCount': analysisResults.length,
        'repCountSource': repCountSource,
        'repCount': report['totalReps'],
        'averageFormScore': report['averageFormScore'],
        'firebaseUploadAttempted': false,
      });

      // Navigate to results screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              report: report,
              exerciseType: widget.exerciseType,
            ),
          ),
        );
      }

    } catch (e) {
      _showErrorDialog('Error processing video: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _uploadToFirebase(Map<String, dynamic> report) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Logger.warning('No authenticated user - skipping Firebase upload', tag: 'FIREBASE');
        return;
      }

      // Check file size before upload (free tier optimization)
      if (_selectedVideo != null) {
        final fileSize = await _selectedVideo!.length();
        const maxUploadSize = 25 * 1024 * 1024; // 25MB limit for free tier
        
        if (fileSize > maxUploadSize) {
          Logger.warning('Video too large for free tier upload - saving analysis only', tag: 'FIREBASE', data: {
            'fileSize': fileSize,
            'maxSize': maxUploadSize,
          });
          
          // Save analysis report without video
          await _saveAnalysisOnly(user, report);
          return;
        }
      }

      Logger.info('Starting Firebase upload with timeout', tag: 'FIREBASE', data: {
        'userId': user.uid,
        'exerciseType': widget.exerciseType,
      });

      // Add timeout to prevent hanging
      await Future.any([
        _performFirebaseUpload(user, report),
        Future.delayed(const Duration(seconds: 10), () {
          throw TimeoutException('Firebase upload timeout', const Duration(seconds: 10));
        }),
      ]);

    } catch (e) {
      Logger.warning('Firebase upload failed or timed out - continuing with local results', tag: 'FIREBASE', data: {'error': e.toString()});
      // Don't show error dialog - just continue with local results
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _saveAnalysisOnly(User user, Map<String, dynamic> report) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('assessments')
          .add({
        'userId': user.uid,
        'exerciseType': widget.exerciseType,
        'videoUrl': null, // No video uploaded
        'report': report,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'local_analysis_complete',
        'hasVideo': false,
        'note': 'Video not uploaded due to size limits (free tier optimization)',
      });

      FirebaseLogger.firestoreWrite('assessments', docRef.id, true);

      Logger.info('Analysis saved without video (free tier optimization)', tag: 'FIREBASE', data: {
        'documentId': docRef.id,
      });
    } catch (e) {
      Logger.warning('Failed to save analysis without video', tag: 'FIREBASE', data: {'error': e.toString()});
    }
  }

  Future<void> _performFirebaseUpload(User user, Map<String, dynamic> report) async {
    // Try to upload video to Firebase Storage
    String? videoUrl;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('videos')
          .child(user.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.mp4');

      Logger.info('Uploading video to Firebase Storage', tag: 'FIREBASE', data: {
        'path': storageRef.fullPath,
      });

      final uploadTask = storageRef.putFile(_selectedVideo!);
      final snapshot = await uploadTask;
      videoUrl = await snapshot.ref.getDownloadURL();

      FirebaseLogger.storageUpload(storageRef.fullPath, true);
    } catch (storageError) {
      Logger.warning('Firebase Storage upload failed, using local fallback', tag: 'FIREBASE', data: {'error': storageError.toString()});
      FirebaseLogger.storageUpload('unknown', false, error: storageError.toString());
      // Continue without video URL - we'll still save the analysis
      videoUrl = null;
    }

    // Save analysis report to Firestore
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('assessments')
          .add({
        'userId': user.uid,
        'exerciseType': widget.exerciseType,
        'videoUrl': videoUrl, // May be null if storage upload failed
        'report': report,
        'createdAt': FieldValue.serverTimestamp(),
        'status': videoUrl != null ? 'pending_cloud_analysis' : 'local_analysis_complete',
        'hasVideo': videoUrl != null,
      });

      FirebaseLogger.firestoreWrite('assessments', docRef.id, true);

      Logger.info('Firebase upload completed successfully', tag: 'FIREBASE', data: {
        'documentId': docRef.id,
        'videoUrl': videoUrl,
      });
    } catch (firestoreError) {
      Logger.warning('Firestore write failed - continuing with local results', tag: 'FIREBASE', data: {'error': firestoreError.toString()});
      // Continue without Firestore - local results are still available
    }
  }

  String _getCameraAngleGuidance() {
    switch (widget.exerciseType) {
        case 'push_up':
          return '📹 CAMERA SETUP:\n• Side view (90°): Best for elbow angle analysis\n• Camera at chest height\n• Show full body from head to feet\n• Ensure elbows are clearly visible\n\n📊 HOW WE COUNT REPS:\n• Rep starts when elbows bend below 120° (down position)\n• Rep completes when elbows straighten above 160° (up position)\n• We track elbow angles with body alignment validation\n\n⭐ FORM SCORING:\n• Elbow angle range: 90-180° is optimal (70% of score)\n• Body alignment: Straight line from head to heels (30%)\n• Higher scores for proper elbow movement with good posture';
      case 'pull_up':
        return '📹 CAMERA SETUP:\n• Side view (90°): Best for head-to-bar analysis\n• Camera at bar height\n• Show full body from head to feet\n• Ensure head, wrists, and elbows are clearly visible\n\n📊 HOW WE COUNT REPS:\n• Rep starts when head goes above wrists (chin over bar)\n• Rep completes when head drops below elbows (full hang)\n• We track head position relative to wrists and elbows\n\n⭐ FORM SCORING:\n• Range of motion: Full extension to chin over bar (60% of score)\n• Body control: Minimal swinging and kipping (40%)\n• Higher scores for controlled movement with full ROM';
      case 'squat':
        return '📹 CAMERA SETUP:\n• Side view (90°): Best for knee angle analysis\n• Camera at knee height\n• Show full body from head to feet\n• Ensure hips, knees, and ankles are clearly visible\n\n📊 HOW WE COUNT REPS:\n• Rep starts when knee angle goes below 90° (deep squat)\n• Rep completes when knees straighten above 160° (standing)\n• We track knee angles formed by hip-knee-ankle\n\n⭐ FORM SCORING:\n• Knee angle range: 70-180° is optimal (70% of score)\n• Depth control: Smooth descent to proper depth (30%)\n• Higher scores for controlled movement with proper knee tracking';
      default:
        return '• Side view (90°) works best\n• Camera at exercise height\n• Show full body movement\n• Ensure good lighting and stability';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload ${widget.exerciseType.replaceAll('_', ' ').toUpperCase()} Video',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video preview section
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedVideo == null
                  ? _buildVideoPlaceholder()
                  : _buildVideoPreview(),
            ),
            
            const SizedBox(height: 24),
            
            // Upload button
            ElevatedButton.icon(
              onPressed: _selectedVideo == null ? _pickVideo : null,
              icon: const Icon(Icons.video_library),
              label: Text(
                _selectedVideo == null ? 'Select Video' : 'Video Selected',
                style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedVideo == null ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            if (_selectedVideo != null) ...[
              const SizedBox(height: 16),
              
              // Process button
              ElevatedButton.icon(
                onPressed: _isProcessing || _isUploading ? null : _processVideo,
                icon: _isProcessing || _isUploading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  _isProcessing || _isUploading ? 'Processing...' : 'Analyze Video',
                  style: GoogleFonts.urbanist(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            
            // Processing progress
            if (_isProcessing || _isUploading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _processingProgress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                _processingStatus,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Camera angle guidance
            const SizedBox(height: 24),
            Container(
              height: 200, // Fixed height to prevent overflow
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Recording Guide & Analysis Info',
                        style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _getCameraAngleGuidance(),
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Record ${widget.exerciseType.replaceAll('_', ' ')} exercises\n'
                    '• Ensure good lighting and clear visibility\n'
                    '• Keep the camera steady and follow angle guidance above\n'
                    '• Perform with proper form for accurate analysis',
                    style: GoogleFonts.urbanist(
                      color: Colors.blue.shade700,
                      height: 1.4,
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

  Widget _buildVideoPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No video selected',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Select Video" to choose a video file',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  List<WorkoutMetric> _generateWorkoutMetrics(Map<String, dynamic> report) {
    final metrics = <WorkoutMetric>[];
    
    if (report.containsKey('totalReps')) {
      metrics.add(WorkoutMetric(
        name: 'Total Reps',
        value: (report['totalReps'] as int).toDouble(),
        unit: 'reps',
        category: 'performance',
      ));
    }
    
    if (report.containsKey('totalDistanceKm')) {
      metrics.add(WorkoutMetric(
        name: 'Distance',
        value: (report['totalDistanceKm'] as double),
        unit: 'km',
        category: 'performance',
      ));
    }
    
    if (report.containsKey('averageFormScore')) {
      metrics.add(WorkoutMetric(
        name: 'Form Score',
        value: (report['averageFormScore'] as double),
        unit: '%',
        category: 'quality',
      ));
    }
    
    if (report.containsKey('videoDuration')) {
      metrics.add(WorkoutMetric(
        name: 'Duration',
        value: (report['videoDuration'] as int).toDouble(),
        unit: 'seconds',
        category: 'time',
      ));
    }
    
    return metrics;
  }
}
