import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/enhanced_metrics_model.dart';
import '../../services/vms_service.dart';
import '../../widgets/enhanced_metrics_widgets.dart';
import '../../config/app_colors.dart';

/// Enhanced VMS Dashboard with comprehensive metrics
class EnhancedVMSDashboardScreen extends StatefulWidget {
  const EnhancedVMSDashboardScreen({super.key});

  @override
  State<EnhancedVMSDashboardScreen> createState() =>
      _EnhancedVMSDashboardScreenState();
}

class _EnhancedVMSDashboardScreenState
    extends State<EnhancedVMSDashboardScreen> {
  final VMSService _vmsService = VMSService();

  bool _isLoading = true;
  MetricsTimeFilter _selectedFilter = MetricsTimeFilter.all;
  EnhancedDashboardStats? _stats;
  String? _error;

  // Theme colors (using AppColors)
  static final primaryColor = AppColors.primaryBlue;
  static final backgroundColor = AppColors.backgroundLight1;
  static final textPrimary = AppColors.textDark;
  static final textSecondary = AppColors.gray1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _vmsService.getEnhancedDashboard(
        filter: _selectedFilter.value,
      );

      setState(() {
        if (response.isSuccess) {
          _stats = response.data;
        } else {
          _error = response.error;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData(String format) async {
    try {
      final response = await _vmsService.exportData(
        format: format,
        filter: _selectedFilter.value,
        metrics: ['calls', 'mood', 'selfEsteem', 'callQuality'],
      );

      if (response.isSuccess) {
        _showSuccess('Export started successfully');
      } else {
        _showError(response.error ?? 'Export failed');
      }
    } catch (e) {
      _showError('Export failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Enhanced VMS Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onSelected: _exportData,
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'csv',
                    child: Text('Export as CSV'),
                  ),
                  const PopupMenuItem(
                    value: 'json',
                    child: Text('Export as JSON'),
                  ),
                ],
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Filter
                      TimeFilterChips(
                        selectedFilter: _selectedFilter,
                        onFilterChanged: (filter) {
                          setState(() => _selectedFilter = filter);
                          _loadData();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Top Metrics Row - Calls (Top Left as requested)
                      _buildTopMetricsSection(),
                      const SizedBox(height: 16),

                      // Volunteer Overview
                      _buildVolunteerStats(),
                      const SizedBox(height: 16),

                      // Call & Quality Metrics
                      _buildCallMetrics(),
                      const SizedBox(height: 16),

                      // Mood & Self-Esteem
                      _buildMoodAndSelfEsteemSection(),
                      const SizedBox(height: 16),

                      // Mentor Ratings & Learning Outcomes
                      _buildMentorSection(),
                      const SizedBox(height: 16),

                      // Gamification Overview
                      _buildGamificationSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: GoogleFonts.poppins(fontSize: 14, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetricsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildHighlightMetric(
              'Total Calls',
              _stats!.calls.total.toString(),
              Icons.phone_rounded,
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildHighlightMetric(
              'Call Hours',
              '${_stats!.calls.totalHours.toStringAsFixed(1)}h',
              Icons.access_time_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildVolunteerStats() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volunteer Overview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Total Volunteers',
                value: _stats!.volunteers.total.toString(),
                icon: Icons.people_rounded,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Active Mentoring',
                value: _stats!.volunteers.inMentoring.toString(),
                icon: Icons.groups_rounded,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCallMetrics() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Call Metrics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Avg per Volunteer',
                value: _stats!.calls.averagePerVolunteer.toStringAsFixed(1),
                subtitle: 'calls per volunteer',
                icon: Icons.person_pin_rounded,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Call Quality',
                value: _stats!.callQuality.average.toStringAsFixed(1),
                subtitle: '${_stats!.callQuality.totalRated} rated',
                icon: Icons.star_rounded,
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoodAndSelfEsteemSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Well-being Metrics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Mood Average',
                value: _stats!.mood.average.toStringAsFixed(1),
                subtitle: 'out of 10',
                icon: Icons.sentiment_satisfied_rounded,
                color: Colors.green,
                trend: _stats!.mood.trend,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Self-Esteem',
                value: _stats!.selfEsteem.average.toStringAsFixed(1),
                subtitle: 'out of 10',
                icon: Icons.favorite_rounded,
                color: Colors.pink,
                trend: _stats!.selfEsteem.trend,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMentorSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mentor Performance',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.purple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mentor Rating',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          StarRatingDisplay(
                            rating: _stats!.mentorRatings.average,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _stats!.mentorRatings.average.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Based on ${_stats!.mentorRatings.totalRated} ratings',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gamification Progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_stats!.gamification.volunteersCompleted12Calls} completed',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_stats!.gamification.averageProgress.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Average Progress Across All Volunteers',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _stats!.gamification.averageProgress / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.deepPurple[400]!,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
