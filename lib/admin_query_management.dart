import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'config/api_config.dart';
import 'config/app_colors.dart';

class AdminQueryManagementPage extends StatefulWidget {
  const AdminQueryManagementPage({super.key});

  @override
  State<AdminQueryManagementPage> createState() => _AdminQueryManagementPageState();
}

class _AdminQueryManagementPageState extends State<AdminQueryManagementPage> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = ApiConfig.apiUrl;
  
  List<dynamic> _queries = [];
  bool _loading = true;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchQueries();
  }

  Future<void> _fetchQueries() async {
    setState(() => _loading = true);
    try {
      final token = await secureStorage.read(key: "adminToken");
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/queries'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _queries = data['queries'] ?? [];
          });
        }
      } else {
        print('Error fetching queries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReply(String queryId, String reply) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      final response = await http.post(
        Uri.parse('$baseUrl/companion-connect/admin/queries/$queryId/reply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reply': reply}),
      );

      if (response.statusCode == 200) {
        _fetchQueries(); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reply sent successfully!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send reply"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateQuery(String queryId, String status, String reply) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 3,
                      ),
                    ),
                    Icon(
                      Icons.edit_rounded,
                      size: 28,
                      color: AppColors.primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Updating Query...',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final response = await http.patch(
        Uri.parse('$baseUrl/companion-connect/admin/queries/$queryId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': status,
          'reply': reply,
        }),
      );

      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        _fetchQueries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Query updated successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to update query');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e', style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteQuery(String queryId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        color: Colors.red.shade400,
                        strokeWidth: 3,
                      ),
                    ),
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 28,
                      color: Colors.red.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Deleting Query...',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final response = await http.delete(
        Uri.parse('$baseUrl/companion-connect/admin/queries/$queryId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      Navigator.pop(context); // Hide loading

      if (response.statusCode == 200) {
        _fetchQueries();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Query deleted successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete query');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e', style: GoogleFonts.poppins(fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingQueries = _queries.where((q) => q['status'] == 'pending').toList();
    final answeredQueries = _queries.where((q) => q['status'] == 'replied').toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Query Management",
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Pending (${pendingQueries.length})"),
            Tab(text: "Replied (${answeredQueries.length})"),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildQueryList(pendingQueries, isPending: true),
                _buildQueryList(answeredQueries, isPending: false),
              ],
            ),
    );
  }

  Widget _buildQueryList(List<dynamic> queries, {required bool isPending}) {
    if (queries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isPending ? "No pending queries" : "No replied queries",
              style: GoogleFonts.poppins(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: queries.length,
      itemBuilder: (context, index) {
        final query = queries[index];
        return _buildQueryCard(query, isPending);
      },
    );
  }

  Widget _buildQueryCard(Map<String, dynamic> query, bool isPending) {
    return _QueryHoverCard(
      query: query,
      isPending: isPending,
      onReply: () => _showReplyDialog(query),
      onEdit: () => _showEditQueryDialog(query),
      onDelete: () => _showDeleteQueryDialog(query),
      formatDate: _formatDate,
    );
  }

  void _showReplyDialog(Map<String, dynamic> query) {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.reply_rounded, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Reply to Query',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              
              // Volunteer Name
              if (query['volunteer'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        query['volunteer']['fullName'] ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              
              // Original Query
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Query:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      query['query'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Reply TextField
              TextField(
                controller: replyController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Type your reply...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (replyController.text.trim().isNotEmpty) {
                          Navigator.pop(context);
                          _submitReply(query['id'] ?? query['_id'], replyController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Send Reply',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditQueryDialog(Map<String, dynamic> query) {
    final TextEditingController replyController = TextEditingController(text: query['reply'] ?? '');
    String selectedStatus = query['status'] ?? 'replied';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Edit Query',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Original Query
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Query:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query['query'] ?? '',
                        style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status Dropdown
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ['pending', 'replied'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Reply TextField
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reply',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: replyController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Update your reply...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (replyController.text.trim().isNotEmpty) {
                            Navigator.pop(context);
                            _updateQuery(
                              query['id'] ?? query['_id'],
                              selectedStatus,
                              replyController.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Update',
                          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
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

  void _showDeleteQueryDialog(Map<String, dynamic> query) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                'Delete Query?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 12),
              
              // Volunteer Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'From: ${query['volunteerName'] ?? 'Unknown'}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Query Preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  query['query'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 20),
              
              // Description
              Text(
                'This action cannot be undone. The query will be permanently removed.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteQuery(query['id'] ?? query['_id']);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return '';
    }
  }
}

// ---------------------------------------------------------------------------
// Hover card – shows volunteer & mentee details on web/desktop hover
// ---------------------------------------------------------------------------
class _QueryHoverCard extends StatefulWidget {
  final Map<String, dynamic> query;
  final bool isPending;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String Function(String?) formatDate;

  const _QueryHoverCard({
    required this.query,
    required this.isPending,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
  });

  @override
  State<_QueryHoverCard> createState() => _QueryHoverCardState();
}

class _QueryHoverCardState extends State<_QueryHoverCard> {
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  // Fetched from API
  Map<String, dynamic>? _volunteer;
  Map<String, dynamic>? _mentee;
  bool _fetched = false;
  bool _fetching = false;

  // Cached position for overlay rebuild after fetch
  Offset? _lastPosition;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  String? get _volunteerId {
    final q = widget.query;
    // Try common field names the API might return
    return q['volunteerId']?.toString() ??
        q['volunteer']?['_id']?.toString() ??
        q['volunteer']?['id']?.toString();
  }

  Future<void> _fetchVolunteerDetails() async {
    if (_fetched || _fetching) return;
    final id = _volunteerId;
    if (id == null) return;

    _fetching = true;
    try {
      final token = await _storage.read(key: 'adminToken');
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/companion-connect/admin/volunteers/$id/mentee'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          _volunteer = data['volunteer'] as Map<String, dynamic>?;
          _mentee = data['mentee'] as Map<String, dynamic>?;
          _fetched = true;
          // Rebuild the overlay with real data
          if (_overlayEntry != null && _lastPosition != null) {
            _removeOverlay();
            _buildAndInsertOverlay(_lastPosition!);
          }
        }
      }
    } catch (_) {}
    _fetching = false;
  }

  void _showOverlayAt(Offset globalPosition) {
    if (!_isDesktopOrWeb) return;
    _hideTimer?.cancel();
    _lastPosition = globalPosition;
    if (_overlayEntry != null) return;
    _buildAndInsertOverlay(globalPosition);
    _fetchVolunteerDetails(); // fetch in background; rebuilds overlay when done
  }

  void _buildAndInsertOverlay(Offset globalPosition) {
    const double popupWidth = 300;
    const double popupMaxHeight = 440;
    final screenSize = MediaQuery.of(context).size;

    double left = globalPosition.dx + 16;
    double top = globalPosition.dy - 20;

    if (left + popupWidth > screenSize.width - 8) {
      left = globalPosition.dx - popupWidth - 16;
    }
    if (top + popupMaxHeight > screenSize.height - 8) {
      top = screenSize.height - popupMaxHeight - 8;
    }
    if (top < 8) top = 8;
    if (left < 8) left = 8;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) => _cancelHide(),
            onExit: (_) => _scheduleHide(),
            child: _buildPopup(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), _removeOverlay);
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  String _fmtDob(String? dob) {
    if (dob == null) return 'N/A';
    try {
      final d = DateTime.parse(dob);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dob.length >= 10 ? dob.substring(0, 10) : dob;
    }
  }

  Widget _buildPopup() {
    final q = widget.query;
    final isPending = widget.isPending;
    final vol = _volunteer;
    final mentee = _mentee;
    final isLoading = !_fetched && _volunteerId != null;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                child: Text(
                  (q['volunteerName'] ?? 'V')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vol?['fullName'] ?? q['volunteerName'] ?? 'Unknown Volunteer',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.orange.withOpacity(0.12)
                      : Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending ? 'Pending' : 'Replied',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPending
                        ? Colors.orange.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // ── Loading spinner ───────────────────────────────────────────────
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              ),
            )
          else ...[
            // ── Volunteer details ─────────────────────────────────────────
            _row(Icons.phone_outlined, 'Phone',
                vol?['phone'] ?? 'N/A'),
            _row(Icons.cake_outlined, 'Date of Birth',
                _fmtDob(vol?['dob']?.toString())),
            _row(Icons.badge_outlined, 'Volunteer Code',
                vol?['volunteerCode'] ?? 'N/A'),
            // _row(Icons.verified_user_outlined, 'Status',
            //     vol?['approvalStatus'] ?? vol?['status'] ?? 'N/A'),
            const SizedBox(height: 8),

            // ── Assigned mentee ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: mentee != null
                    ? AppColors.accentGreen.withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: mentee != null
                      ? AppColors.accentGreen.withOpacity(0.35)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        mentee != null
                            ? Icons.person_rounded
                            : Icons.person_off_outlined,
                        size: 14,
                        color: mentee != null
                            ? AppColors.accentGreen
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          mentee != null
                              ? mentee['fullName'] ?? 'Unknown Mentee'
                              : 'No mentee assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: mentee != null
                                ? AppColors.accentGreen
                                : Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (mentee != null) ...[
                    const SizedBox(height: 6),
                    _menteeRow(Icons.cake_outlined, 'Age',
                        '${mentee['age'] ?? 'N/A'}'),
                    _menteeRow(Icons.calendar_today_outlined, 'DOB',
                        _fmtDob(mentee['dob']?.toString())),
                    _menteeRow(Icons.phone_outlined, 'Phone',
                        mentee['phone'] ?? 'N/A'),
                    _menteeRow(Icons.grid_view_rounded, 'Cell',
                        'Cell ${mentee['currentCell'] ?? 'N/A'}'),
                    _menteeRow(Icons.circle, 'Status',
                        mentee['status'] ?? 'N/A'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.grey.shade500)),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _menteeRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: AppColors.accentGreen.withOpacity(0.7)),
          const SizedBox(width: 5),
          Text('$label: ',
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.accentGreen.withOpacity(0.8))),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final isPending = widget.isPending;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  child: Text(
                    (q['volunteerName'] ?? 'V')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q['volunteerName'] ?? 'Unknown Volunteer',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        widget.formatDate(q['createdAt']),
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Replied',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isPending
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                q['query'] ?? '',
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
              ),
            ),
            if (!isPending && q['reply'] != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Reply:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q['reply'],
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    tooltip: 'Delete Query',
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onReply,
                    icon: Icon(Icons.reply, size: 16),
                    label: Text('Reply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
            if (!isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: Icon(Icons.delete_outline, size: 20),
                    color: Colors.red,
                    tooltip: 'Delete Query',
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!_isDesktopOrWeb) return card;

    return MouseRegion(
      onEnter: (event) => _showOverlayAt(event.position),
      onExit: (_) => _scheduleHide(),
      child: card,
    );
  }
}
