import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vms_dashboard_model.dart';
import '../config/app_colors.dart';

/// A stat card for displaying dashboard statistics
class DashboardStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  factory DashboardStatCard.fromStatItem(DashboardStatItem item, {VoidCallback? onTap}) {
    return DashboardStatCard(
      title: item.title,
      value: item.value,
      icon: _getIconData(item.icon),
      color: _getColor(item.color),
      subtitle: item.subtitle,
      onTap: onTap,
    );
  }

  static IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'people':
        return Icons.people_rounded;
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'person_add':
        return Icons.person_add_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'logout':
        return Icons.logout_rounded;
      case 'workspace_premium':
        return Icons.workspace_premium_rounded;
      case 'card_membership':
        return Icons.card_membership_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  static Color _getColor(DashboardStatColor statColor) {
    switch (statColor) {
      case DashboardStatColor.blue:
        return AppColors.primaryBlue;
      case DashboardStatColor.orange:
        return AppColors.accentOrange;
      case DashboardStatColor.purple:
        return AppColors.purpleGradientEnd;
      case DashboardStatColor.teal:
        return AppColors.secondaryBlue;
      case DashboardStatColor.green:
        return AppColors.accentGreen;
      case DashboardStatColor.red:
        return AppColors.accentOrange;
      case DashboardStatColor.amber:
        return AppColors.accentYellow;
      case DashboardStatColor.indigo:
        return AppColors.primaryBlue;
      case DashboardStatColor.pink:
        return AppColors.pinkAccent;
      case DashboardStatColor.cyan:
        return AppColors.tertiaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  Text(
                    value.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact version of the stat card for smaller displays
class CompactStatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CompactStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.gray1,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
