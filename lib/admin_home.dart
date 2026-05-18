import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_companionconnect.dart';
import 'admin.dart';
import 'config/app_colors.dart';
import 'screens/admin/admin_notifications_screen.dart';
import 'screens/admin/neomami_admin_screen.dart';
import 'screens/admin/heartbeat_admin_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<void> _logout() async {
    await secureStorage.delete(key: "adminToken");
    if (mounted) {
      Navigator.pushReplacementNamed(context, "/admin-login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight1,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primaryBlue,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Admin Dashboard',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
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
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 100,
                        height: 100,
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
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/notifications');
                },
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(
                  Icons.settings_suggest_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/admin/vms/dashboard');
                },
                tooltip: 'VMS & CCP Controls',
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Welcome Section
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back! 👋',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a module to get started',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: AppColors.gray1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Grid Section
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Builder(
                  builder: (context) {
                    final width = MediaQuery.of(context).size.width;
                    final int columns =
                        width >= 900
                            ? 3
                            : width >= 600
                            ? 2
                            : 2;
                    final double aspectRatio =
                        width >= 900
                            ? 1.25
                            : width >= 600
                            ? 1.1
                            : 0.85;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: columns,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        childAspectRatio: aspectRatio,
                        children: [
                          _buildModuleCard(
                            context,
                            title: 'Notifications',
                            subtitle: 'Send & Track',
                            icon: Icons.notifications_rounded,
                            color: const Color(0xFF7B68EE),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF7B68EE), Color(0xFF9B88FF)],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const AdminNotificationsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModuleCard(
                            context,
                            title: 'Companion\nConnect',
                            subtitle: 'Mentee & Analytics',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.accentGreen,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentGreen,
                                AppColors.accentGreen.withOpacity(0.7),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const AdminCompanionConnectScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModuleCard(
                            context,
                            title: 'Volunteers\nManagement',
                            subtitle: 'Approve & Manage',
                            icon: Icons.how_to_reg_rounded,
                            color: AppColors.primaryBlue,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryBlue,
                                AppColors.secondaryBlue,
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminScreen(),
                                ),
                              );
                            },
                          ),
                          _buildModuleCard(
                            context,
                            title: 'Heartbeat',
                            subtitle: 'Volunteer Hours',
                            icon: Icons.favorite_rounded,
                            color: AppColors.tertiaryBlue,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.tertiaryBlue,
                                AppColors.secondaryBlue,
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const HeartbeatAdminPage(),
                                ),
                              );
                            },
                          ),
                          _buildModuleCard(
                            context,
                            title: 'Neomami\nHub',
                            subtitle: 'Volunteer Activity',
                            icon: Icons.book_rounded,
                            color: AppColors.accentGreen,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.accentGreen,
                                AppColors.accentGreen.withOpacity(0.7),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const NeomamAdminScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
