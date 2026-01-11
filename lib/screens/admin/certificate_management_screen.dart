import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/volunteer_model.dart';
import '../../services/vms_service.dart';

/// Certificate Management Screen for viewing and issuing certificates
class CertificateManagementScreen extends StatefulWidget {
  const CertificateManagementScreen({super.key});

  @override
  State<CertificateManagementScreen> createState() => _CertificateManagementScreenState();
}

class _CertificateManagementScreenState extends State<CertificateManagementScreen>
    with SingleTickerProviderStateMixin {
  final VMSService _vmsService = VMSService();
  late TabController _tabController;
  
  bool _isLoading = true;
  List<Volunteer> _eligibleVolunteers = [];
  List<Volunteer> _issuedVolunteers = [];

  // Theme colors
  static const primaryColor = Color(0xFF1E88E5);
  static const backgroundColor = Color(0xFFF8FFFE);
  static const textPrimary = Color(0xFF2C3E50);
  static const textSecondary = Color(0xFF7F8C8D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load eligible volunteers
      final eligibleResponse = await _vmsService.getVolunteersByStage('certificate-eligible');
      // Load issued volunteers
      final issuedResponse = await _vmsService.getVolunteersByStage('certificate-issued');

      setState(() {
        if (eligibleResponse.isSuccess) {
          _eligibleVolunteers = eligibleResponse.data ?? [];
        }
        if (issuedResponse.isSuccess) {
          _issuedVolunteers = issuedResponse.data ?? [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load data: $e');
    }
  }

  Future<void> _issueCertificate(Volunteer volunteer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Issue Certificate',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to issue a certificate to ${volunteer.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Issue Certificate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _showLoadingOverlay();

    final response = await _vmsService.issueCertificate(volunteer.id);

    Navigator.pop(context); // Hide loading

    if (response.isSuccess) {
      _showSuccess('Certificate issued to ${volunteer.displayName}');
      _loadData();
    } else {
      _showError(response.error ?? 'Failed to issue certificate');
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Processing...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          'Certificate Management',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Eligible (${_eligibleVolunteers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.card_membership_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text('Issued (${_issuedVolunteers.length})'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildEligibleTab(),
                _buildIssuedTab(),
              ],
            ),
    );
  }

  Widget _buildEligibleTab() {
    if (_eligibleVolunteers.isEmpty) {
      return _buildEmptyState(
        'No Eligible Volunteers',
        'No volunteers are currently eligible for certificates',
        Icons.workspace_premium_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _eligibleVolunteers.length,
        itemBuilder: (context, index) {
          final volunteer = _eligibleVolunteers[index];
          return _buildCertificateCard(volunteer, isEligible: true);
        },
      ),
    );
  }

  Widget _buildIssuedTab() {
    if (_issuedVolunteers.isEmpty) {
      return _buildEmptyState(
        'No Certificates Issued',
        'No certificates have been issued yet',
        Icons.card_membership_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _issuedVolunteers.length,
        itemBuilder: (context, index) {
          final volunteer = _issuedVolunteers[index];
          return _buildCertificateCard(volunteer, isEligible: false);
        },
      ),
    );
  }

  Widget _buildCertificateCard(Volunteer volunteer, {required bool isEligible}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 28,
                  backgroundImage: volunteer.photoUrl != null
                      ? NetworkImage(volunteer.photoUrl!)
                      : null,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: volunteer.photoUrl == null
                      ? Icon(Icons.person_rounded, size: 28, color: primaryColor)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Volunteer Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Volunteer Code
                      if (volunteer.volunteerCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            volunteer.volunteerCode!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      
                      // Name
                      Text(
                        volunteer.displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      
                      // Email
                      if (volunteer.email != null)
                        Text(
                          volunteer.email!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      
                      // Duration
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 14, color: textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Duration: ${volunteer.durationDisplay}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Certificate Status Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEligible
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEligible
                        ? Icons.workspace_premium_rounded
                        : Icons.verified_rounded,
                    color: isEligible ? Colors.amber[700] : Colors.green,
                    size: 28,
                  ),
                ),
              ],
            ),
            
            // Action Button for Eligible
            if (isEligible) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _issueCertificate(volunteer),
                  icon: const Icon(Icons.card_membership_rounded, size: 18),
                  label: Text(
                    'Issue Certificate',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            
            // Issued Date for Issued Certificates
            if (!isEligible && volunteer.certificateIssuedDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_available_rounded, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Issued on: ${_formatDate(volunteer.certificateIssuedDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
