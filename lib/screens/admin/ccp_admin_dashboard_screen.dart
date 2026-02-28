import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:universal_html/html.dart' as html;
import '../../config/api_config.dart';
import '../../config/app_colors.dart';

class CCPAdminDashboardScreen extends StatefulWidget {
  const CCPAdminDashboardScreen({super.key});

  @override
  State<CCPAdminDashboardScreen> createState() => _CCPAdminDashboardScreenState();
}

class _CCPAdminDashboardScreenState extends State<CCPAdminDashboardScreen> {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  List<dynamic> _volunteers = [];
  List<dynamic> _mentees = [];
  List<dynamic> _queries = [];
  
  // Add state for detailed volunteer view
  Map<String, dynamic>? _selectedVolunteerDetails;
  bool _loadingVolunteerDetails = false;
  
  // Add missing state variables
  int _totalVolunteers = 0;
  int _activeVolunteers = 0;
  int _totalMentees = 0;
  int _assignedMentees = 0;
  int _unassignedMentees = 0;
  int _pendingQueries = 0;
  int _totalCallHours = 0;
  double _avgCallDuration = 0.0;
  
  // Red flags data
  List<Map<String, dynamic>> _volunteersWithRedFlags = [];
  int _totalRedFlags = 0;

  // Volunteer list expand/collapse
  bool _showAllVolunteers = false;
  
  // Additional insights data
  Map<String, int> _topicFrequency = {};
  Map<String, int> _assistanceFrequency = {};
  Map<String, int> _checklistCompletion = {};
  Map<String, int> _mentorHelpfulnessFrequency = {};
  List<Map<String, dynamic>> _moodTrends = [];
  List<Map<String, dynamic>> _callDurationDistribution = [];
  Map<String, int> _followUpTrends = {};
  
  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }
  
  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await secureStorage.read(key: "adminToken");
      
      if (token == null) {
        _showError("Authentication token not found. Please login again.");
        return;
      }
      
      // Fetch all data in parallel
      await Future.wait([
        _fetchVolunteers(token),
        _fetchMentees(token),
        _fetchQueries(token),
      ]);
      
      // Calculate metrics
      _calculateMetrics();
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() => _isLoading = false);
      _showError("Error loading dashboard data");
    }
  }
  
  Future<void> _fetchVolunteers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/companion-connect/volunteers'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('=== VOLUNTEERS API RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final basicVolunteers = data['volunteers'] ?? [];
          print('Total volunteers fetched: ${basicVolunteers.length}');

          // Fetch detailed data for ALL volunteers in parallel
          print('Fetching detailed data for ${basicVolunteers.length} volunteers in parallel...');
          
          final List<Future<Map<String, dynamic>>> detailFutures = [];
          
          for (var volunteer in basicVolunteers) {
            detailFutures.add(_fetchSingleVolunteerData(volunteer, token));
          }

          // Wait for all requests to complete
          _volunteers = await Future.wait(detailFutures);
          
          print('✅ Successfully fetched details for ${_volunteers.length} volunteers in parallel');
          if (_volunteers.isNotEmpty) {
            print('First volunteer keys: ${_volunteers[0].keys}');
            print('First volunteer has callRecords: ${_volunteers[0].containsKey("callRecords")}');
            if (_volunteers[0].containsKey('callRecords')) {
              print('First volunteer callRecords count: ${(_volunteers[0]['callRecords'] as List?)?.length ?? 0}');
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching volunteers: $e');
    }
  }
  
  Future<Map<String, dynamic>> _fetchSingleVolunteerData(Map<String, dynamic> volunteer, String token) async {
    final volunteerId = volunteer['_id'];
    
    try {
      final detailResponse = await http.get(
        Uri.parse('$baseUrl/admin/companion-connect/volunteers/$volunteerId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (detailResponse.statusCode == 200) {
        final detailData = json.decode(detailResponse.body);
        if (detailData['success'] == true) {
          // Merge basic volunteer data with detailed data
          return {
            ...volunteer,
            'callRecords': detailData['callRecords'] ?? [],
            'insights': detailData['insights'] ?? volunteer['insights'] ?? {},
          };
        }
      }
    } catch (detailError) {
      print('Error fetching details for ${volunteer['fullName']}: $detailError');
    }
    
    // Fallback to basic data if detail fetch fails
    return volunteer;
  }
  
  Future<void> _fetchMentees(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/mentees'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _mentees = data['mentees'] ?? [];
        }
      }
    } catch (e) {
      print('Error fetching mentees: $e');
    }
  }
  
  Future<void> _fetchQueries(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/companion-connect/admin/queries'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _queries = data['queries'] ?? [];
        }
      }
    } catch (e) {
      print('Error fetching queries: $e');
    }
  }
  
  void _calculateMetrics() {
    // The new endpoint already returns filtered Companion Connect volunteers
    final ccVolunteers = _volunteers;
    
    _totalVolunteers = ccVolunteers.length;
    
    // Active volunteers: all returned volunteers are approved (endpoint filters this)
    _activeVolunteers = ccVolunteers.length;
    
    _totalMentees = _mentees.length;
    _assignedMentees = _mentees.where((m) => m['assignedTo'] != null).length;
    _unassignedMentees = _totalMentees - _assignedMentees;
    
    _pendingQueries = _queries.where((q) => q['status'] == 'pending').length;
    
    // Reset detailed insights data before processing all volunteers
    _topicFrequency = {};
    _assistanceFrequency = {};
    _checklistCompletion = {};
    _mentorHelpfulnessFrequency = {};
    _moodTrends = [];
    _callDurationDistribution = [];
    _followUpTrends = {};
    
    // Calculate call statistics from insights data
    int totalCalls = 0;
    double totalHours = 0;
    int totalRatings = 0;
    double totalRatingSum = 0;
    _volunteersWithRedFlags = [];
    _totalRedFlags = 0;
    
    for (var volunteer in ccVolunteers) {
      final insights = volunteer['insights'];
      if (insights != null) {
        totalCalls += (insights['totalCalls'] as int?) ?? 0;
        final callHours = insights['totalCallHours'];
        if (callHours != null) {
          if (callHours is String) {
            totalHours += double.tryParse(callHours) ?? 0;
          } else {
            totalHours += (callHours as num?)?.toDouble() ?? 0;
          }
        }
        
        final avgRating = (insights['averageRating'] as num?)?.toDouble();
        final ratingCount = (insights['totalRatings'] as int?) ?? 0;
        if (avgRating != null && ratingCount > 0) {
          totalRatingSum += avgRating * ratingCount;
          totalRatings += ratingCount;
        }
        
        // Extract red flags data
        final callsWithRedFlags = (insights['callsWithRedFlags'] as int?) ?? 0;
        if (callsWithRedFlags > 0) {
          _volunteersWithRedFlags.add({
            'volunteer': volunteer,
            'redFlagsCount': callsWithRedFlags,
          });
          _totalRedFlags += callsWithRedFlags;
        }
        
        // Extract detailed insights from call records if available
        final callRecords = volunteer['callRecords'] as List?;
        if (callRecords != null && callRecords.isNotEmpty) {
          print('Processing ${callRecords.length} call records for volunteer ${volunteer['fullName']}');
          _extractDetailedInsights(callRecords);
        } else {
          print('No call records for volunteer ${volunteer['fullName']}');
        }
      }
    }
    
    print('=== INSIGHTS SUMMARY ===');
    print('Topics found: ${_topicFrequency.length} - $_topicFrequency');
    print('Assistance requests: ${_assistanceFrequency.length} - $_assistanceFrequency');
    print('Checklist items: ${_checklistCompletion.length} - $_checklistCompletion');
    print('Mentor helpfulness: ${_mentorHelpfulnessFrequency.length} - $_mentorHelpfulnessFrequency');
    print('Mood trends: ${_moodTrends.length}');
    print('Call duration ranges: ${_callDurationDistribution.length}');
    print('Follow-up dates: ${_followUpTrends.length}');
    print('========================');
    
    _totalCallHours = totalHours.round();
    _avgCallDuration = totalCalls > 0 ? (totalHours * 60) / totalCalls : 0;
  }
  
  void _extractDetailedInsights(List<dynamic> callRecords) {
    // Process each call record (do NOT reset data - accumulate across all volunteers)
    for (var call in callRecords) {
      // Topics frequency
      final topics = call['topics'] as List?;
      if (topics != null) {
        for (var topic in topics) {
          _topicFrequency[topic.toString()] = (_topicFrequency[topic.toString()] ?? 0) + 1;
        }
      }
      
      // Assistance requests frequency
      final assistanceRequests = call['assistanceRequest'] as List?;
      if (assistanceRequests != null) {
        for (var request in assistanceRequests) {
          _assistanceFrequency[request.toString()] = (_assistanceFrequency[request.toString()] ?? 0) + 1;
        }
      }
      
      // Mentor helpfulness frequency
      final mentorHelpfulness = call['mentorHelpfulness'] as String?;
      if (mentorHelpfulness != null && mentorHelpfulness.isNotEmpty) {
        _mentorHelpfulnessFrequency[mentorHelpfulness] = (_mentorHelpfulnessFrequency[mentorHelpfulness] ?? 0) + 1;
      }
      
      // Checklist completion - only add achieved items
      final checklist = call['checklist'] as List?;
      if (checklist != null) {
        for (var item in checklist) {
          final label = item['label'].toString();
          final achieved = item['isAchieved'] == true;
          
          // Only increment if achieved
          if (achieved) {
            _checklistCompletion[label] = (_checklistCompletion[label] ?? 0) + 1;
          }
        }
      }
      
      // Mood trends over time
      final callDate = call['callDate'];
      final moodScore = call['moodScore'];
      if (callDate != null && moodScore != null) {
        _moodTrends.add({
          'date': DateTime.parse(callDate),
          'mood': moodScore,
        });
      }
      
      // Call duration distribution
      final duration = call['callDuration'] as int?;
      if (duration != null) {
        final durationRange = _getDurationRange(duration);
        final existing = _callDurationDistribution.firstWhere(
          (d) => d['range'] == durationRange,
          orElse: () => <String, dynamic>{},
        );
        if (existing.isNotEmpty) {
          existing['count'] = (existing['count'] as int) + 1;
        } else {
          _callDurationDistribution.add({
            'range': durationRange,
            'count': 1,
          });
        }
      }
      
      // Follow-up trends
      final followUpRequired = call['followUpRequired'] == true;
      if (followUpRequired) {
        final date = call['callDate'];
        if (date != null) {
          final dateKey = DateTime.parse(date).toString().split(' ')[0];
          _followUpTrends[dateKey] = (_followUpTrends[dateKey] ?? 0) + 1;
        }
      }
    }
    
    // Sort mood trends by date
    _moodTrends.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Sort call duration distribution
    _callDurationDistribution.sort((a, b) => (a['count'] as int).compareTo(b['count'] as int));
  }
  
  String _getDurationRange(int minutes) {
    if (minutes < 15) return '< 15 min';
    if (minutes < 30) return '15-30 min';
    if (minutes < 45) return '30-45 min';
    if (minutes < 60) return '45-60 min';
    return '> 60 min';
  }
  
  Future<void> _fetchVolunteerDetails(String volunteerId) async {
    setState(() => _loadingVolunteerDetails = true);
    
    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/companion-connect/volunteers/$volunteerId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      print('Volunteer Details Response Status: ${response.statusCode}');
      print('Volunteer Details Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded data: $data');
        print('Call Records count: ${(data['callRecords'] as List?)?.length ?? 0}');
        
        if (data['success'] == true) {
          setState(() {
            _selectedVolunteerDetails = data;
          });
          _showVolunteerDetailsDialog();
        } else {
          _showError('Failed to load volunteer details: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching volunteer details: $e');
      _showError('Error loading volunteer details: $e');
    }
    
    setState(() => _loadingVolunteerDetails = false);
  }
  
  Future<void> _fetchCallDetails(String volunteerId, String callId) async {
    try {
      final token = await secureStorage.read(key: "adminToken");
      if (token == null) return;
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/companion-connect/volunteers/$volunteerId/calls/$callId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showCallDetailsDialog(data['callNote']);
        } else {
          _showError('Failed to load call details');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching call details: $e');
      _showError('Error loading call details: $e');
    }
  }
  
  void _showVolunteerDetailsDialog() {
    if (_selectedVolunteerDetails == null) return;
    
    final volunteer = _selectedVolunteerDetails!['volunteer'];
    final assignedMentee = _selectedVolunteerDetails!['assignedMentee'];
    final callRecords = _selectedVolunteerDetails!['callRecords'] as List? ?? [];
    final insights = _selectedVolunteerDetails!['insights'];
    
    print('=== Volunteer Details Dialog ===');
    print('Volunteer: ${volunteer?['fullName']}');
    print('Call Records Length: ${callRecords.length}');
    print('Call Records: $callRecords');
    print('Insights: $insights');
    print('==============================');
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    child: Icon(Icons.person, color: AppColors.primaryBlue, size: 30),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer['fullName'] ?? 'Unknown',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Code: ${volunteer['volunteerCode'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (volunteer['email'] != null) ...[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.email, size: 10, color: Colors.grey.shade600),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  volunteer['email'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (volunteer['phone'] != null) ...[
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.phone, size: 10, color: Colors.grey.shade600),
                              SizedBox(width: 4),
                              Text(
                                volunteer['phone'],
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _downloadVolunteerCSV(volunteer['_id'], volunteer['fullName'], callRecords),
                    icon: Icon(Icons.download),
                    tooltip: 'Download CSV',
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Insights Cards
              Row(
                children: [
                  _buildDetailCard(
                    'Total Calls',
                    insights?['totalCalls']?.toString() ?? '0',
                    Icons.phone,
                    AppColors.primaryBlue,
                  ),
                  SizedBox(width: 12),
                  _buildDetailCard(
                    'Total Hours',
                    '${insights?['totalCallHours'] ?? '0'}h',
                    Icons.access_time,
                    AppColors.accentGreen,
                  ),
                  SizedBox(width: 12),
                  _buildDetailCard(
                    'Avg Mood',
                    insights?['averageMood']?.toString() ?? 'N/A',
                    Icons.mood,
                    AppColors.accentOrange,
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Assigned Mentee
              if (assignedMentee != null) ...[
                Text(
                  'Assigned Mentee',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.accentGreen),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignedMentee['fullName'] ?? 'Unknown',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Age: ${assignedMentee['age'] ?? 'N/A'} • Cell: ${assignedMentee['currentCell'] ?? 'N/A'}',
                              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Call Records
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Call Records (${callRecords.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: callRecords.isEmpty
                          ? Center(
                              child: Text(
                                'No call records yet',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: callRecords.length,
                              itemBuilder: (context, index) {
                                final call = callRecords[index];
                                final hasRedFlags = call['redFlags'] != null && call['redFlags'].toString().isNotEmpty;
                                final followUpRequired = call['followUpRequired'] == true;
                                
                                return InkWell(
                                  onTap: () => _fetchCallDetails(volunteer['_id'], call['_id']),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: hasRedFlags ? Colors.red.withOpacity(0.05) : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: hasRedFlags ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
                                        width: hasRedFlags ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primaryBlue.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'Cell ${call['cellNumber'] ?? 'N/A'}',
                                                      style: GoogleFonts.poppins(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                        color: AppColors.primaryBlue,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Call #${index + 1}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (call['callDate'] != null) ...[
                                                SizedBox(height: 4),
                                                Text(
                                                  DateTime.parse(call['callDate']).toString().split('.')[0],
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                              SizedBox(height: 8),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 4,
                                                children: [
                                                  _buildCallMetric(Icons.access_time, '${call['callDuration'] ?? 0} min', AppColors.accentGreen),
                                                  _buildCallMetric(Icons.mood, '${call['moodScore'] ?? 'N/A'}/5', AppColors.accentOrange),
                                                  if (call['volunteerComfort'] != null)
                                                    _buildCallMetric(Icons.favorite, 'Comfort: ${call['volunteerComfort']}/5', Colors.pink),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            if (hasRedFlags)
                                              Padding(
                                                padding: EdgeInsets.only(bottom: 4),
                                                child: Icon(Icons.warning, color: Colors.red, size: 18),
                                              ),
                                            if (call['followUpRequired'] == true)
                                              Icon(Icons.flag, color: Colors.orange, size: 18),
                                          ],
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
  
  void _showCallDetailsDialog(Map<String, dynamic> call) {
    final hasRedFlags = call['redFlags'] != null && call['redFlags'].toString().isNotEmpty;
    final topics = call['topics'] as List? ?? [];
    final assistanceRequests = call['assistanceRequest'] as List? ?? [];
    final checklist = call['checklist'] as List? ?? [];
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Cell ${call['cellNumber'] ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  Spacer(),
                  if (hasRedFlags)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Red Flag',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              
              if (call['callDate'] != null) ...[
                SizedBox(height: 4),
                Text(
                  DateTime.parse(call['callDate']).toString().split('.')[0],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              
              SizedBox(height: 20),
              
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Call Metrics Card
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetricItem(
                              Icons.access_time,
                              'Duration',
                              '${call['callDuration'] ?? 0} min',
                              AppColors.accentGreen,
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            _buildMetricItem(
                              Icons.mood,
                              'Mood',
                              '${call['moodScore'] ?? 'N/A'}/5',
                              AppColors.accentOrange,
                            ),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            _buildMetricItem(
                              Icons.favorite,
                              'Comfort',
                              '${call['volunteerComfort'] ?? 'N/A'}/5',
                              Colors.pink,
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      
                      // Topics Section
                      if (topics.isNotEmpty) ...[
                        _buildSectionHeader('Topics Discussed', Icons.topic, Colors.blue),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics.map((topic) => Chip(
                            label: Text(
                              topic.toString(),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                          )).toList(),
                        ),
                        if (topics.contains('Others') && call['otherTopicDetail'] != null && call['otherTopicDetail'].toString().isNotEmpty) ...[
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Other Topic Details:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  call['otherTopicDetail'],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20),
                      ],
                      
                      // Focus Areas Section
                      if (checklist.isNotEmpty) ...[
                        () {
                          final achieved = checklist.where((item) => item['isAchieved'] == true).toList();
                          if (achieved.isEmpty) return SizedBox.shrink();
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader('Focus Areas Achieved', Icons.check_circle_outline, AppColors.accentGreen),
                              SizedBox(height: 8),
                              ...achieved.map((item) => Container(
                                margin: EdgeInsets.only(bottom: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.accentGreen.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['label'].toString(),
                                        style: GoogleFonts.poppins(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              )).toList(),
                              SizedBox(height: 20),
                            ],
                          );
                        }(),
                      ],
                      
                      // Assistance Requests Section
                      if (assistanceRequests.isNotEmpty) ...[
                        _buildSectionHeader('Assistance Needed', Icons.help_outline, Colors.purple),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: assistanceRequests.map((request) => Chip(
                            label: Text(
                              request.toString(),
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            side: BorderSide(color: Colors.purple.withOpacity(0.3)),
                          )).toList(),
                        ),
                        if (assistanceRequests.contains('Other Concern') && call['assistanceRequestOtherDetail'] != null && call['assistanceRequestOtherDetail'].toString().isNotEmpty) ...[
                          SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Other Concern Details:',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  call['assistanceRequestOtherDetail'],
                                  style: GoogleFonts.poppins(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20),
                      ],
                      
                      // Observation Notes
                      if (call['note'] != null && call['note'].toString().isNotEmpty) ...[
                        _buildSectionHeader('Observation Notes', Icons.notes, Colors.grey.shade700),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            call['note'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      
                      // Red Flags Alert
                      if (hasRedFlags) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'RED FLAGS',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                call['redFlags'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      
                      // Volunteer Comments
                      if (call['volunteerNote'] != null && call['volunteerNote'].toString().isNotEmpty) ...[
                        _buildSectionHeader('Volunteer Comments', Icons.person_outline, Colors.blue),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Text(
                            call['volunteerNote'],
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                      
                      // Additional Information
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (call['mentorHelpfulness'] != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.thumb_up, size: 16, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mentor Helpful: ',
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    call['mentorHelpfulness'].toString(),
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                            if (call['followUpRequired'] == true) ...[
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.flag, size: 16, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Follow-up Required',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCallMetric(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Excel download: one sheet per volunteer + overall summary sheet
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _downloadAllVolunteersExcel() async {
    // Ask user which volunteers to include
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.table_chart, color: Colors.green.shade700),
            SizedBox(width: 8),
            Text(
              'Download Excel',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Which volunteers should be included in the Excel file?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'withCalls'),
            icon: Icon(Icons.phone, size: 16),
            label: Text('With Calls Only', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, 'all'),
            icon: Icon(Icons.people, size: 16),
            label: Text('All Volunteers', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (choice == null) return; // cancelled

    final volunteersToExport = choice == 'withCalls'
        ? _volunteers.where((v) {
            final calls = v['callRecords'] as List?;
            return calls != null && calls.isNotEmpty;
          }).toList()
        : _volunteers.toList();

    if (volunteersToExport.isEmpty) {
      _showError('No volunteers to export for the selected filter.');
      return;
    }

    try {
      final excel = xls.Excel.createExcel();
      // Use filtered list for export
      final exportList = volunteersToExport;

      // ── Header style helper ───────────────────────────────────────────────
      xls.CellStyle headerStyle() {
        return xls.CellStyle(
          bold: true,
          backgroundColorHex: xls.ExcelColor.fromHexString('#1565C0'),
          fontColorHex: xls.ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: xls.HorizontalAlign.Center,
        );
      }

      xls.CellStyle subHeaderStyle() {
        return xls.CellStyle(
          bold: true,
          backgroundColorHex: xls.ExcelColor.fromHexString('#E3F2FD'),
          fontColorHex: xls.ExcelColor.fromHexString('#0D47A1'),
        );
      }

      // ── Per-volunteer sheets ──────────────────────────────────────────────
      for (var volunteer in exportList) {
        final name = (volunteer['fullName'] as String? ?? 'Unknown')
            .replaceAll(RegExp(r'[\\/*?:\[\]]'), '_');
        // Excel sheet names max 31 chars
        final sheetName = name.length > 31 ? name.substring(0, 31) : name;

        final sheet = excel[sheetName];
        final callRecords = volunteer['callRecords'] as List? ?? [];
        final insights = volunteer['insights'] ?? {};

        // Volunteer summary block
        sheet.appendRow([xls.TextCellValue('Volunteer Summary')]);
        sheet.cell(xls.CellIndex.indexByString('A1')).cellStyle = subHeaderStyle();

        final summaryRows = [
          ['Full Name', volunteer['fullName'] ?? ''],
          ['Email', volunteer['email'] ?? ''],
          ['Phone', volunteer['phone'] ?? ''],
          ['Status', volunteer['status'] ?? ''],
          ['Total Calls', insights['totalCalls']?.toString() ?? '0'],
          ['Total Call Hours', insights['totalCallHours']?.toString() ?? '0'],
          ['Average Rating', (insights['averageRating'] as num?)?.toStringAsFixed(2) ?? '0'],
          ['Red Flag Calls', insights['callsWithRedFlags']?.toString() ?? '0'],
        ];
        for (var row in summaryRows) {
          sheet.appendRow([xls.TextCellValue(row[0]), xls.TextCellValue(row[1])]);
        }
        sheet.appendRow([xls.TextCellValue('')]);

        // Call records header
        final callHeaders = [
          'Date', 'Cell Number', 'Duration (min)', 'Topics',
          'Assistance Requests', 'Checklist Items (Achieved)',
          'Mood Score', 'Mentor Helpfulness', 'Follow Up Required',
          'Red Flags', 'Notes', 'Volunteer Note',
        ];
        final headerRow = callHeaders.map((h) => xls.TextCellValue(h)).toList();
        sheet.appendRow(headerRow);

        // Style the call header row (it starts at row index = summaryRows.length + 2)
        final callHeaderRowIdx = summaryRows.length + 2; // 0-based index
        for (var c = 0; c < callHeaders.length; c++) {
          sheet
              .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: callHeaderRowIdx))
              .cellStyle = headerStyle();
        }

        for (var call in callRecords) {
          final date = call['callDate'] != null
              ? DateTime.parse(call['callDate']).toString().split(' ')[0]
              : '';
          final cellNumber = call['cellNumber']?.toString() ?? '';
          final duration = call['callDuration']?.toString() ?? '';
          final topics = (call['topics'] as List?)?.join('; ') ?? '';
          final assistance = (call['assistanceRequest'] as List?)?.join('; ') ?? '';
          final checklist = (call['checklist'] as List?)
                  ?.where((item) => item['isAchieved'] == true)
                  .map((item) => item['label'].toString())
                  .join('; ') ??
              '';
          final mood = call['moodScore']?.toString() ?? '';
          final mentorHelp = call['mentorHelpfulness']?.toString() ?? '';
          final followUp = call['followUpRequired'] == true ? 'Yes' : 'No';
          final redFlags = call['redFlags']?.toString() ?? '';
          final notes = call['note']?.toString() ?? '';
          final volunteerNote = call['volunteerNote']?.toString() ?? '';

          sheet.appendRow([
            xls.TextCellValue(date),
            xls.TextCellValue(cellNumber),
            xls.TextCellValue(duration),
            xls.TextCellValue(topics),
            xls.TextCellValue(assistance),
            xls.TextCellValue(checklist),
            xls.TextCellValue(mood),
            xls.TextCellValue(mentorHelp),
            xls.TextCellValue(followUp),
            xls.TextCellValue(redFlags),
            xls.TextCellValue(notes),
            xls.TextCellValue(volunteerNote),
          ]);
        }

        // Set column widths
        for (var c = 0; c < callHeaders.length; c++) {
          sheet.setColumnWidth(c, 20.0);
        }
      }

      // ── Overall summary sheet ─────────────────────────────────────────────
      const overallName = 'Overall Summary';
      final overallSheet = excel[overallName];

      // Remove default blank sheet if it exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Programme metrics header
      final metricsHeaders = ['Metric', 'Value'];
      overallSheet.appendRow(metricsHeaders.map((h) => xls.TextCellValue(h)).toList());
      for (var c = 0; c < metricsHeaders.length; c++) {
        overallSheet
            .cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
            .cellStyle = headerStyle();
      }

      final metrics = [
        ['Total Volunteers', _totalVolunteers.toString()],
        ['Active Volunteers', _activeVolunteers.toString()],
        ['Total Mentees', _totalMentees.toString()],
        ['Assigned Mentees', _assignedMentees.toString()],
        ['Unassigned Mentees', _unassignedMentees.toString()],
        ['Pending Queries', _pendingQueries.toString()],
        ['Total Call Hours', _totalCallHours.toString()],
        ['Avg Call Duration (min)', _avgCallDuration.toStringAsFixed(1)],
        ['Total Red Flags', _totalRedFlags.toString()],
      ];
      for (var row in metrics) {
        overallSheet.appendRow([xls.TextCellValue(row[0]), xls.TextCellValue(row[1])]);
      }

      overallSheet.appendRow([xls.TextCellValue('')]);

      // Topics
      overallSheet.appendRow([xls.TextCellValue('Topics Discussed'), xls.TextCellValue('Count')]);
      for (var entry in (_topicFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {
        overallSheet.appendRow([xls.TextCellValue(entry.key), xls.TextCellValue(entry.value.toString())]);
      }
      overallSheet.appendRow([xls.TextCellValue('')]);

      // Assistance
      overallSheet.appendRow([xls.TextCellValue('Assistance Requests'), xls.TextCellValue('Count')]);
      for (var entry in (_assistanceFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {
        overallSheet.appendRow([xls.TextCellValue(entry.key), xls.TextCellValue(entry.value.toString())]);
      }
      overallSheet.appendRow([xls.TextCellValue('')]);

      // Checklist
      overallSheet.appendRow([xls.TextCellValue('Checklist Items (Achieved)'), xls.TextCellValue('Count')]);
      for (var entry in (_checklistCompletion.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {
        overallSheet.appendRow([xls.TextCellValue(entry.key), xls.TextCellValue(entry.value.toString())]);
      }
      overallSheet.appendRow([xls.TextCellValue('')]);

      // Mentor helpfulness
      overallSheet.appendRow([xls.TextCellValue('Mentor Helpfulness'), xls.TextCellValue('Count')]);
      for (var entry in (_mentorHelpfulnessFrequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))) {
        overallSheet.appendRow([xls.TextCellValue(entry.key), xls.TextCellValue(entry.value.toString())]);
      }

      overallSheet.setColumnWidth(0, 30.0);
      overallSheet.setColumnWidth(1, 15.0);

      // Set overall sheet as first tab
      excel.setDefaultSheet(overallName);

      // Encode and trigger browser download
      final encoded = excel.encode();
      if (encoded == null) {
        _showError('Failed to generate Excel file.');
        return;
      }
      final bytes = Uint8List.fromList(encoded);
      final blob = html.Blob(
          [bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'CCP_Volunteers_Calls.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel downloaded: ${exportList.length} volunteer sheets + Overall'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showError('Error generating Excel: $e');
    }
  }

  void _downloadVolunteerCSV(String volunteerId, String volunteerName, List<dynamic> callRecords) {
    try {
      // Prepare CSV data
      List<List<String>> csvData = [
        ['Date', 'Cell Number', 'Duration (min)', 'Topics', 'Assistance Requests', 'Checklist Items', 'Mood Score', 'Red Flags', 'Notes', 'Volunteer Note']
      ];
      
      for (var call in callRecords) {
        final date = call['callDate'] != null ? DateTime.parse(call['callDate']).toString().split(' ')[0] : '';
        final cellNumber = call['cellNumber']?.toString() ?? '';
        final duration = call['callDuration']?.toString() ?? '';
        final topics = (call['topics'] as List?)?.join('; ') ?? '';
        final assistance = (call['assistanceRequest'] as List?)?.join('; ') ?? '';
        final checklist = (call['checklist'] as List?)?.map((item) => '${item['label']}: ${item['isAchieved']}').join('; ') ?? '';
        final mood = call['moodScore']?.toString() ?? '';
        final redFlags = call['redFlags']?.toString() ?? '';
        final notes = call['note']?.toString() ?? '';
        final volunteerNote = call['volunteerNote']?.toString() ?? '';
        
        csvData.add([date, cellNumber, duration, topics, assistance, checklist, mood, redFlags, notes, volunteerNote]);
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Create and download file
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${volunteerName.replaceAll(' ', '_')}_calls.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      _showError('CSV downloaded successfully!');
    } catch (e) {
      _showError('Error downloading CSV: $e');
    }
  }
  
  void _downloadOverallCSV() {
    try {
      // Prepare overall metrics CSV
      List<List<String>> csvData = [
        ['Metric', 'Value'],
        ['Total Volunteers', _totalVolunteers.toString()],
        ['Active Volunteers', _activeVolunteers.toString()],
        ['Total Mentees', _totalMentees.toString()],
        ['Assigned Mentees', _assignedMentees.toString()],
        ['Unassigned Mentees', _unassignedMentees.toString()],
        ['Pending Queries', _pendingQueries.toString()],
        ['Total Call Hours', _totalCallHours.toString()],
        ['Average Call Duration', _avgCallDuration.toStringAsFixed(1)],
        ['Total Red Flags', _totalRedFlags.toString()],
      ];
      
      // Add topics
      csvData.add(['', '']);
      csvData.add(['Topics Frequency', '']);
      for (var entry in _topicFrequency.entries) {
        csvData.add([entry.key, entry.value.toString()]);
      }
      
      // Add assistance
      csvData.add(['', '']);
      csvData.add(['Assistance Requests', '']);
      for (var entry in _assistanceFrequency.entries) {
        csvData.add([entry.key, entry.value.toString()]);
      }
      
      // Add checklist
      csvData.add(['', '']);
      csvData.add(['Checklist Completion', '']);
      for (var entry in _checklistCompletion.entries) {
        csvData.add([entry.key, entry.value.toString()]);
      }
      
      // Add mentor helpfulness
      csvData.add(['', '']);
      csvData.add(['Mentor Helpfulness', '']);
      for (var entry in _mentorHelpfulnessFrequency.entries) {
        csvData.add([entry.key, entry.value.toString()]);
      }
      
      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);
      
      // Create and download file
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'companion_connect_analytics.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      
      _showError('Overall CSV downloaded successfully!');
    } catch (e) {
      _showError('Error downloading CSV: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        foregroundColor: Colors.white,
        title: Text(
          "Companion Connect Analytics",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.table_chart),
            onPressed: _downloadAllVolunteersExcel,
            tooltip: "Download All Volunteers Excel (.xlsx)",
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadOverallCSV,
            tooltip: "Download Overall CSV",
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
            tooltip: "Refresh Data",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Metrics
                    _buildOverviewSection(),
                    
                    SizedBox(height: 24),
                    
                    // Call Statistics
                    _buildCallStatisticsSection(),
                    
                    SizedBox(height: 24),
                    
                    // Mentee Assignment Status
                    _buildMenteeAssignmentSection(),
                    
                    SizedBox(height: 24),
                    
                    // CCP Volunteers Chart
                    _buildTopPerformersSection(),
                    
                    SizedBox(height: 24),
                    
                    // Recent Queries
                    _buildQueriesSection(),
                    
                    // Red Flags Section
                    if (_volunteersWithRedFlags.isNotEmpty) ...[
                      SizedBox(height: 24),
                      _buildRedFlagsSection(),
                    ],
                    
                    // Additional Insights Sections - ALWAYS SHOW
                    SizedBox(height: 24),
                    _buildTopicsInsightsSection(),
                    
                    SizedBox(height: 24),
                    _buildAssistanceInsightsSection(),
                    
                    SizedBox(height: 24),
                    _buildMentorHelpfulnessSection(),
                    
                    SizedBox(height: 24),
                    _buildChecklistInsightsSection(),
                    
                    SizedBox(height: 24),
                    _buildMoodTrendsSection(),
                    
                    SizedBox(height: 24),
                    _buildCallDurationSection(),
                    
                    SizedBox(height: 24),
                    _buildFollowUpTrendsSection(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Program Overview",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.dark2,
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              "Total Volunteers",
              _totalVolunteers.toString(),
              Icons.people,
              AppColors.primaryBlue,
            ),
            _buildMetricCard(
              "Active Volunteers",
              _activeVolunteers.toString(),
              Icons.verified_user,
              AppColors.accentGreen,
            ),
            _buildMetricCard(
              "Total Mentees",
              _totalMentees.toString(),
              Icons.school,
              AppColors.accentOrange,
            ),
            _buildMetricCard(
              "Pending Queries",
              _pendingQueries.toString(),
              Icons.help_outline,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCallStatisticsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_in_talk, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Call Statistics",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  "Total Hours",
                  "$_totalCallHours hrs",
                  Icons.access_time,
                  AppColors.accentGreen,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  "Avg Duration",
                  "${_avgCallDuration.toStringAsFixed(1)} min",
                  Icons.timer,
                  AppColors.accentOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenteeAssignmentSection() {
    final assignmentPercentage = _totalMentees > 0 
        ? (_assignedMentees / _totalMentees * 100).toStringAsFixed(0)
        : "0";
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.accentGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Mentee Assignments",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _assignedMentees.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGreen,
                      ),
                    ),
                    Text(
                      "Assigned",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: Colors.grey.shade300,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _unassignedMentees.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      "Unassigned",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Center(
            child: Text(
              "$assignmentPercentage% Assignment Rate",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTopPerformersSection() {
    // Sort volunteers by total call hours from insights
    final sortedVolunteers = _volunteers.toList();
    sortedVolunteers.sort((a, b) {
      final aHours = (a['insights']?['totalCallHours'] as num?)?.toDouble() ?? 0;
      final bHours = (b['insights']?['totalCallHours'] as num?)?.toDouble() ?? 0;
      return bHours.compareTo(aHours);
    });
    
    // Show ALL volunteers, not just top 5
    final allVolunteers = sortedVolunteers;
    
    if (allVolunteers.isEmpty) {
      return SizedBox.shrink();
    }
    
    // Max hours for progress bar scaling
    final maxHours = allVolunteers.isNotEmpty
        ? (allVolunteers.first['insights']?['totalCallHours'] as num?)?.toDouble() ?? 1
        : 1.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber.shade700),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "CCP Volunteers (${allVolunteers.length})",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _downloadAllVolunteersExcel,
                icon: Icon(Icons.download, size: 18, color: Colors.green.shade700),
                label: Text(
                  "Download Excel",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Volunteer list — initially collapsed to 5
          Column(
            children: (_showAllVolunteers ? allVolunteers : allVolunteers.take(5).toList()).asMap().entries.map((entry) {
              final index = entry.key;
              final volunteer = entry.value;
              final insights = volunteer['insights'] ?? {};
              final hours = (insights['totalCallHours'] as num?)?.toDouble() ?? 0;
              final calls = (insights['totalCalls'] as int?) ?? 0;
              final avgRating = (insights['averageRating'] as num?)?.toDouble() ?? 0;
              final name = volunteer['fullName'] as String? ?? 'Unknown';
              final hasRedFlags = volunteer['hasRedFlags'] as bool? ?? false;
              
              final percentage = maxHours > 0 ? (hours / maxHours) : 0.0;
              
              return _DashVolunteerHoverCard(
                index: index,
                volunteer: volunteer,
                hours: hours,
                calls: calls,
                avgRating: avgRating,
                percentage: percentage,
                hasRedFlags: hasRedFlags,
                onTap: () => _fetchVolunteerDetails(volunteer['_id']),
              );
          }).toList(),
          ),
          // See More / See Less toggle
          if (allVolunteers.length > 5) ...
            [
              SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAllVolunteers = !_showAllVolunteers),
                  icon: Icon(
                    _showAllVolunteers ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  label: Text(
                    _showAllVolunteers
                        ? 'See Less'
                        : 'See More (${allVolunteers.length - 5} more)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildQueriesSection() {
    final recentQueries = _queries.take(5).toList();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.question_answer, color: AppColors.primaryBlue),
                  SizedBox(width: 8),
                  Text(
                    "Recent Queries",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_pendingQueries > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$_pendingQueries pending",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (recentQueries.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No queries yet",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentQueries.map((query) {
              final isPending = query['status'] == 'pending';
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending ? Colors.red.withOpacity(0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPending ? Colors.red.withOpacity(0.3) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            query['volunteer']?['fullName'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'Pending' : 'Replied',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      query['query'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildRedFlagsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text(
                "Red Flags Overview",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Total Red Flags",
                  _totalRedFlags.toString(),
                  Icons.flag,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildMetricCard(
                  "Volunteers with Red Flags",
                  _volunteersWithRedFlags.length.toString(),
                  Icons.people,
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (_volunteersWithRedFlags.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(
              "Volunteers with Red Flags:",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            ..._volunteersWithRedFlags.map((item) {
              final volunteer = item['volunteer'];
              final redFlagsCount = item['redFlagsCount'];
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            volunteer['fullName'] ?? 'Unknown',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade800,
                            ),
                          ),
                          Text(
                            "Code: ${volunteer['volunteerCode'] ?? 'N/A'}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$redFlagsCount flags",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTopicsInsightsSection() {
    final sortedTopics = _topicFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    print('Building topics section with ${sortedTopics.length} topics');
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.topic, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Topics Discussed",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (sortedTopics.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No topic data available yet. Topics will appear after volunteers make calls.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...sortedTopics.take(6).map((entry) {
              final percentage = sortedTopics.isNotEmpty 
                  ? (entry.value / sortedTopics.first.value) * 100 
                  : 0.0;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildMentorHelpfulnessSection() {
    final sortedHelpfulness = _mentorHelpfulnessFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Mentor Helpfulness",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (sortedHelpfulness.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No mentor helpfulness data available yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...sortedHelpfulness.take(6).map((entry) {
              final percentage = sortedHelpfulness.isNotEmpty 
                  ? (entry.value / sortedHelpfulness.first.value) * 100 
                  : 0.0;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildAssistanceInsightsSection() {
    final sortedAssistance = _assistanceFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                "Assistance Requests",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (sortedAssistance.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No assistance requests data available yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedAssistance.map((entry) {
                return Chip(
                  label: Text(
                    '${entry.key}: ${entry.value}',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  side: BorderSide(color: Colors.purple.withOpacity(0.3)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildChecklistInsightsSection() {
    final sortedChecklist = _checklistCompletion.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.accentGreen),
              SizedBox(width: 8),
              Text(
                "Focus Areas Achievement",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (sortedChecklist.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No checklist completion data available yet.',
                  style: GoogleFonts.poppins(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...sortedChecklist.map((entry) {
              final percentage = sortedChecklist.isNotEmpty 
                  ? (entry.value / sortedChecklist.first.value) * 100 
                  : 0.0;
              
              return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value} times',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildMoodTrendsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                "Mood Trends Over Time",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _moodTrends.length,
              itemBuilder: (context, index) {
                final trend = _moodTrends[index];
                final mood = trend['mood'] as int;
                final date = trend['date'] as DateTime;
                
                return Container(
                  width: 60,
                  margin: EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: double.infinity,
                                height: (mood / 5) * 140,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Center(
                                child: Text(
                                  mood.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${date.month}/${date.day}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Scale: 1 (Lowest) - 5 (Highest)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCallDurationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                "Call Duration Distribution",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._callDurationDistribution.map((duration) {
            final range = duration['range'] as String;
            final count = duration['count'] as int;
            final maxCount = _callDurationDistribution.isNotEmpty 
                ? _callDurationDistribution.first['count'] as int 
                : 1;
            final percentage = maxCount > 0 ? (count / maxCount) * 100 : 0.0;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        range,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '$count calls',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildFollowUpTrendsSection() {
    final sortedTrends = _followUpTrends.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                "Follow-up Requirements Trend",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sortedTrends.length,
              itemBuilder: (context, index) {
                final trend = sortedTrends[index];
                final date = trend.key;
                final count = trend.value;
                final maxCount = sortedTrends.isNotEmpty 
                    ? sortedTrends.map((t) => t.value).reduce((a, b) => a > b ? a : b)
                    : 1;
                final percentage = maxCount > 0 ? (count / maxCount) * 100 : 0.0;
                
                return Container(
                  width: 50,
                  margin: EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: 30,
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                width: double.infinity,
                                height: percentage * 1.2,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              Center(
                                child: Text(
                                  count.toString(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        date.split('-').last,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Hover card: shows volunteer details + assigned mentee on web/desktop hover
// ──────────────────────────────────────────────────────────────────────────────
class _DashVolunteerHoverCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> volunteer;
  final double hours;
  final int calls;
  final double avgRating;
  final double percentage;
  final bool hasRedFlags;
  final VoidCallback onTap;

  const _DashVolunteerHoverCard({
    required this.index,
    required this.volunteer,
    required this.hours,
    required this.calls,
    required this.avgRating,
    required this.percentage,
    required this.hasRedFlags,
    required this.onTap,
  });

  @override
  State<_DashVolunteerHoverCard> createState() =>
      _DashVolunteerHoverCardState();
}

class _DashVolunteerHoverCardState extends State<_DashVolunteerHoverCard> {
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  Map<String, dynamic>? _volunteer;
  Map<String, dynamic>? _mentee;
  bool _fetched = false;
  bool _fetching = false;
  Offset? _lastPos;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  String? get _volunteerId =>
      widget.volunteer['_id']?.toString() ??
      widget.volunteer['id']?.toString();

  Future<void> _fetchDetails() async {
    if (_fetched || _fetching) return;
    final id = _volunteerId;
    if (id == null) return;
    _fetching = true;
    try {
      final token = await _storage.read(key: 'adminToken');
      final res = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/companion-connect/admin/volunteers/$id/mentee'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['success'] == true && mounted) {
          _volunteer = data['volunteer'] as Map<String, dynamic>?;
          _mentee = data['mentee'] as Map<String, dynamic>?;
          _fetched = true;
          if (_overlayEntry != null && _lastPos != null) {
            _removeOverlay();
            _insertOverlay(_lastPos!);
          }
        }
      }
    } catch (_) {}
    _fetching = false;
  }

  void _showOverlayAt(Offset pos) {
    if (!_isDesktopOrWeb) return;
    _hideTimer?.cancel();
    _lastPos = pos;
    if (_overlayEntry != null) return;
    _insertOverlay(pos);
    _fetchDetails();
  }

  void _insertOverlay(Offset pos) {
    const w = 300.0;
    const maxH = 460.0;
    final screen = MediaQuery.of(context).size;
    double left = pos.dx + 16;
    double top = pos.dy - 20;
    if (left + w > screen.width - 8) left = pos.dx - w - 16;
    if (top + maxH > screen.height - 8) top = screen.height - maxH - 8;
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

  void _cancelHide() => _hideTimer?.cancel();

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

  Widget _popRow(IconData icon, String label, String value,
      {Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(icon, size: 13,
              color: iconColor ?? Colors.grey.shade500),
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
          Icon(icon, size: 11,
              color: AppColors.accentGreen.withOpacity(0.7)),
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

  Widget _buildPopup() {
    final v = widget.volunteer;
    final vol = _volunteer;
    final mentee = _mentee;
    final isLoading = !_fetched && _volunteerId != null;
    final hasRedFlags = widget.hasRedFlags;

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
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
                child: Text(
                  (v['fullName'] ?? 'V')[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vol?['fullName'] ?? v['fullName'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasRedFlags)
                Icon(Icons.warning_rounded,
                    color: Colors.red, size: 18),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primaryBlue),
                ),
              ),
            )
          else ...[
            // ── Volunteer details ───────────────────────────────────────
            _popRow(Icons.phone_outlined, 'Phone',
                vol?['phone'] ?? v['phone'] ?? 'N/A'),
            _popRow(Icons.cake_outlined, 'Date of Birth',
                _fmtDob(vol?['dob']?.toString() ?? v['dob']?.toString())),
            _popRow(Icons.badge_outlined, 'Volunteer Code',
                vol?['volunteerCode'] ?? v['volunteerCode'] ?? 'N/A'),
            // _popRow(Icons.verified_user_outlined, 'Status',
            //     vol?['approvalStatus'] ?? vol?['status'] ??
            //         v['approvalStatus'] ?? v['status'] ?? 'N/A'),
            // ── Stats row ──────────────────────────────────────────────
            _popRow(Icons.timer_outlined, 'Call Hours',
                '${widget.hours.toStringAsFixed(1)} h'),
            _popRow(Icons.call_outlined, 'Total Calls',
                '${widget.calls}'),
            if (widget.avgRating > 0)
              _popRow(Icons.star_outline_rounded, 'Avg Rating',
                  widget.avgRating.toStringAsFixed(1),
                  iconColor: Colors.amber.shade700),
            const SizedBox(height: 8),

            // ── Assigned mentee ─────────────────────────────────────────
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
                              ? (mentee['fullName'] ?? 'Unknown Mentee')
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

  @override
  Widget build(BuildContext context) {
    final v = widget.volunteer;
    final name = v['fullName'] as String? ?? 'Unknown';

    final card = InkWell(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.index == 0
              ? Colors.amber.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.index == 0
                ? Colors.amber.shade200
                : (widget.hasRedFlags
                    ? Colors.red.shade200
                    : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.index == 0
                    ? Colors.amber.shade700
                    : (widget.hasRedFlags
                        ? Colors.red
                        : AppColors.primaryBlue),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.hasRedFlags)
                        const Icon(Icons.warning,
                            color: Colors.red, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.percentage,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accentGreen),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.hours.toStringAsFixed(1)}h',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${widget.calls} calls',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600)),
                      if (widget.avgRating > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star,
                            size: 10, color: Colors.amber),
                        Text(
                          '${widget.avgRating.toStringAsFixed(1)}',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!_isDesktopOrWeb) return card;

    return MouseRegion(
      onEnter: (e) => _showOverlayAt(e.position),
      onExit: (_) => _scheduleHide(),
      child: card,
    );
  }
}
