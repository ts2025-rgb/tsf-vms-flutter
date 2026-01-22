import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/enhanced_metrics_model.dart';
import '../config/app_colors.dart';

/// Widget to display gamification progress with 12-call milestone
class GamificationProgressWidget extends StatelessWidget {
  final VolunteerProgress progress;
  final VoidCallback? onTap;

  const GamificationProgressWidget({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.deepPurple[600]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          progress.volunteerName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${progress.totalCallsCompleted}/${progress.callsGoal} Calls Complete',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${progress.progressPercentage.toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress.progressPercentage / 100,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400]!,
                              Colors.deepPurple[600]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Milestones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    progress.milestones.map((milestone) {
                      return _buildMilestone(
                        milestone.callNumber,
                        milestone.achieved,
                        progress.nextMilestone == milestone.callNumber,
                      );
                    }).toList(),
              ),

              if (progress.estimatedCompletionDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Est. completion: ${_formatDate(progress.estimatedCompletionDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestone(int number, bool achieved, bool isNext) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                achieved
                    ? LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    )
                    : isNext
                    ? LinearGradient(
                      colors: [Colors.orange[400]!, Colors.orange[600]!],
                    )
                    : null,
            color: !achieved && !isNext ? Colors.grey[300] : null,
            border: Border.all(
              color: isNext ? Colors.orange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child:
                achieved
                    ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                    : Text(
                      '$number',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isNext ? Colors.white : Colors.grey[700],
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achieved
              ? 'Done'
              : isNext
              ? 'Next'
              : 'Goal',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Widget for displaying metric cards with trend indicators
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? trend;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (trend != null) _buildTrendIndicator(trend!),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    Color trendColor;
    IconData trendIcon;

    switch (trend.toLowerCase()) {
      case 'improving':
        trendColor = Colors.green;
        trendIcon = Icons.trending_up_rounded;
        break;
      case 'declining':
        trendColor = Colors.red;
        trendIcon = Icons.trending_down_rounded;
        break;
      default:
        trendColor = Colors.grey;
        trendIcon = Icons.trending_flat_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          const SizedBox(width: 4),
          Text(
            trend,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Time filter chip selector
class TimeFilterChips extends StatelessWidget {
  final MetricsTimeFilter selectedFilter;
  final Function(MetricsTimeFilter) onFilterChanged;

  const TimeFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            MetricsTimeFilter.values.map((filter) {
              final isSelected = filter == selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter.displayName),
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged(filter),
                  backgroundColor: Colors.grey[100],
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                  checkmarkColor: AppColors.primaryBlue,
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected ? AppColors.primaryBlue : Colors.grey[700],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

/// Star rating display widget
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color color;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 16,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star_rounded, size: size, color: color);
        } else if (index < rating) {
          return Icon(Icons.star_half_rounded, size: size, color: color);
        } else {
          return Icon(
            Icons.star_border_rounded,
            size: size,
            color: Colors.grey[300],
          );
        }
      }),
    );
  }
}
