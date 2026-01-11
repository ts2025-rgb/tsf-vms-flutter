import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vms_dashboard_model.dart';

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
        return const Color(0xFF1E88E5);
      case DashboardStatColor.orange:
        return const Color(0xFFFF9800);
      case DashboardStatColor.purple:
        return const Color(0xFF9C27B0);
      case DashboardStatColor.teal:
        return const Color(0xFF26A69A);
      case DashboardStatColor.green:
        return const Color(0xFF4CAF50);
      case DashboardStatColor.red:
        return const Color(0xFFE53935);
      case DashboardStatColor.amber:
        return const Color(0xFFFFC107);
      case DashboardStatColor.indigo:
        return const Color(0xFF3F51B5);
      case DashboardStatColor.pink:
        return const Color(0xFFE91E63);
      case DashboardStatColor.cyan:
        return const Color(0xFF00BCD4);
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
                      color: const Color(0xFF2C3E50),
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
                  color: const Color(0xFF7F8C8D),
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
                        color: const Color(0xFF7F8C8D),
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
