import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_mentee_management.dart';
import 'admin_query_management.dart';
import 'config/app_colors.dart';
import 'screens/admin/ccp_admin_dashboard_screen.dart';
import 'screens/admin/admin_management.dart';
import 'screens/admin/resource_management_screen.dart';

class AdminCompanionConnectScreen extends StatefulWidget {
  const AdminCompanionConnectScreen({super.key});

  @override
  State<AdminCompanionConnectScreen> createState() =>
      _AdminCompanionConnectScreenState();
}

class _AdminCompanionConnectScreenState
    extends State<AdminCompanionConnectScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.accentGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Companion Connect',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentGreen,
                      AppColors.accentGreen.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Title Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Your Mentoring Program',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access mentee management, analytics, and query resolution',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.gray1,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Module Cards Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildModuleCard(
                  context,
                  title: 'Mentee Management',
                  description: 'Add, edit, and manage mentees in the program',
                  icon: Icons.school_rounded,
                  color: AppColors.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminMenteeManagementPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  title: 'Analytics Dashboard',
                  description:
                      'View comprehensive analytics and progress tracking',
                  icon: Icons.analytics_rounded,
                  color: AppColors.accentGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CCPAdminDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  title: 'Query Management',
                  description: 'Review and respond to volunteer queries',
                  icon: Icons.question_answer_rounded,
                  color: AppColors.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminQueryManagementPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  title: 'Resource Management',
                  description: 'Manage learning resources and materials',
                  icon: Icons.library_books_rounded,
                  color: AppColors.accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminResourceManagementScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildModuleCard(
                  context,
                  title: 'Admin Management',
                  description: 'Create and manage administrator accounts',
                  icon: Icons.admin_panel_settings_rounded,
                  color: AppColors.secondaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminManagementPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.gray1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.gray1,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
