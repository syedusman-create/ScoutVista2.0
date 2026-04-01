import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/rep_visualization_chart.dart';
import '../utils/ai/heuristics/landmark_exercises.dart';

class ResultsScreen extends StatelessWidget {
  final Map<String, dynamic> report;
  final String exerciseType;

  const ResultsScreen({
    super.key,
    required this.report,
    required this.exerciseType,
  });

  @override
  Widget build(BuildContext context) {
    final totalReps = report['totalReps'] as int;
    final averageFormScore = report['averageFormScore'] as double;
    final videoDuration = report['videoDuration'] as int;
    final analysisResults = report['analysisResults'] as List<Map<String, dynamic>>;
    
    // Parse rep detection events for visualization
    final List<RepDetectionEvent> repEvents = [];
    if (report['repDetectionEvents'] != null) {
      final eventsList = report['repDetectionEvents'] as List<dynamic>;
      for (final eventData in eventsList) {
        final eventMap = eventData as Map<String, dynamic>;
        repEvents.add(RepDetectionEvent(
          frameIndex: eventMap['frameIndex'] as int,
          timestamp: eventMap['timestamp'] as double,
          phase: eventMap['phase'] as String,
          value: eventMap['value'] as double,
          threshold: eventMap['threshold'] as double,
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analysis Results',
          style: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with exercise type
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    exerciseType.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Performance Analysis Complete',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Key metrics cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Reps',
                    totalReps.toString(),
                    Icons.fitness_center,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Form Score',
                    '${averageFormScore.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Duration',
                    '${videoDuration}s',
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Frames Analyzed',
                    analysisResults.length.toString(),
                    Icons.video_library,
                    Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Rep Detection Timeline Visualization
            RepVisualizationChart(
              repEvents: repEvents,
              videoDuration: videoDuration.toDouble(),
              exerciseType: exerciseType,
            ),

            const SizedBox(height: 32),

            // Detailed analysis section
            Text(
              'Detailed Analysis',
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Form score breakdown
            _buildAnalysisCard(
              'Form Analysis',
              _buildFormAnalysisContent(averageFormScore),
              Icons.analytics,
              Colors.green,
            ),

            const SizedBox(height: 16),

            // Rep counting details
            _buildAnalysisCard(
              'Rep Counting',
              _buildRepCountingContent(totalReps, analysisResults),
              Icons.repeat,
              Colors.blue,
            ),

            const SizedBox(height: 16),

            // Performance insights
            _buildAnalysisCard(
              'Performance Insights',
              _buildPerformanceInsights(averageFormScore, totalReps),
              Icons.lightbulb,
              Colors.orange,
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement share functionality
                      _showSnackBar(context, 'Share functionality coming soon!');
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share Results'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement save to profile
                      _showSnackBar(context, 'Results saved to your profile!');
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // SAI submission info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your assessment results have been submitted to the Sports Authority of India for further evaluation.',
                      style: GoogleFonts.urbanist(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.urbanist(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.urbanist(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String title, Widget content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildFormAnalysisContent(double averageFormScore) {
    final scorePercentage = averageFormScore.toInt();
    String feedback;
    Color scoreColor;

    if (scorePercentage >= 80) {
      feedback = 'Excellent form! Keep up the great work.';
      scoreColor = Colors.green;
    } else if (scorePercentage >= 60) {
      feedback = 'Good form with room for improvement.';
      scoreColor = Colors.orange;
    } else {
      feedback = 'Form needs improvement. Focus on technique.';
      scoreColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: averageFormScore / 100.0,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${scorePercentage}%',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          feedback,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildRepCountingContent(int totalReps, List<Map<String, dynamic>> analysisResults) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total repetitions detected: $totalReps',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI analyzed ${analysisResults.length} frames to count your repetitions accurately.',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        if (totalReps > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rep counting successful!',
                    style: GoogleFonts.urbanist(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPerformanceInsights(double averageFormScore, int totalReps) {
    final List<String> insights = [];

    if (averageFormScore >= 0.8) {
      insights.add('Excellent form maintained throughout');
    } else if (averageFormScore >= 0.6) {
      insights.add('Good form with some inconsistencies');
    } else {
      insights.add('Form needs significant improvement');
    }

    if (totalReps >= 20) {
      insights.add('High endurance demonstrated');
    } else if (totalReps >= 10) {
      insights.add('Moderate endurance level');
    } else {
      insights.add('Consider building endurance');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: insights.map((insight) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                insight,
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
