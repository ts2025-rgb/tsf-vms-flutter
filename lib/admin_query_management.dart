import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminQueryManagementPage extends StatefulWidget {
  const AdminQueryManagementPage({super.key});

  @override
  State<AdminQueryManagementPage> createState() => _AdminQueryManagementPageState();
}

class _AdminQueryManagementPageState extends State<AdminQueryManagementPage> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final String baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api"; // Same base URL
  
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

  @override
  Widget build(BuildContext context) {
    final pendingQueries = _queries.where((q) => q['status'] == 'pending').toList();
    final answeredQueries = _queries.where((q) => q['status'] == 'replied').toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Query Management",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color(0xFF6366F1),
          tabs: [
            Tab(text: "Pending (${pendingQueries.length})"),
            Tab(text: "Replied (${answeredQueries.length})"),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    (query['volunteerName'] ?? 'V')[0].toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: Color(0xFF6366F1),
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
                        query['volunteerName'] ?? 'Unknown Volunteer',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        _formatDate(query['createdAt']),
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPending ? "Pending" : "Replied",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isPending ? Colors.orange.shade800 : Colors.green.shade800,
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
                query['query'] ?? '',
                style: GoogleFonts.poppins(fontSize: 13, height: 1.5),
              ),
            ),
            if (!isPending && query['reply'] != null) ...[
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
                          "Admin Reply:",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          query['reply'],
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _showReplyDialog(query),
                  icon: Icon(Icons.reply, size: 16),
                  label: Text("Reply"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Map<String, dynamic> query) {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Reply to Query", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Query:",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
             Text(
              query['query'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 13, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Type your reply...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (replyController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _submitReply(query['id'] ?? query['_id'], replyController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366F1), foregroundColor: Colors.white),
            child: Text("Send Reply"),
          ),
        ],
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
