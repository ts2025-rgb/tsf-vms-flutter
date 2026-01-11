import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/volunteer_model.dart';
import '../models/vms_dashboard_model.dart';

/// Service class for VMS (Volunteer Management System) API calls
class VMSService {
  final String baseUrl;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  VMSService({
    this.baseUrl = "https://shrew-concrete-cobra.ngrok-free.app/api",
  });

  /// Get admin token from secure storage
  Future<String?> _getAdminToken() async {
    return await _secureStorage.read(key: "adminToken");
  }

  /// Common headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAdminToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  /// GET /admin/vms/dashboard - Get VMS dashboard statistics
  Future<VMSServiceResponse<VMSDashboardStats>> getDashboard() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vms/dashboard'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = VMSDashboardStats.fromJson(data['stats'] ?? data);
        return VMSServiceResponse.success(stats);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// GET /admin/vms/stage/:stage - Get volunteers by lifecycle stage
  Future<VMSServiceResponse<List<Volunteer>>> getVolunteersByStage(String stage) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vms/stage/$stage'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteersJson = data['volunteers'] as List? ?? [];
        final volunteers = volunteersJson
            .map((v) => Volunteer.fromJson(v as Map<String, dynamic>))
            .toList();
        return VMSServiceResponse.success(volunteers);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// GET /admin/vms/volunteer/:identifier - Get volunteer details by ID or code
  Future<VMSServiceResponse<Volunteer>> getVolunteerDetails(String identifier) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vms/volunteer/$identifier'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// PATCH /admin/vms/:id/onboarding - Update onboarding status
  Future<VMSServiceResponse<Volunteer>> updateOnboardingStatus(
    String id, 
    OnboardingStatus status,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/vms/$id/onboarding'),
        headers: headers,
        body: json.encode({'status': status.value}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// PATCH /admin/vms/:id/training - Update training status
  Future<VMSServiceResponse<Volunteer>> updateTrainingStatus(
    String id, 
    TrainingStatus status, {
    DateTime? scheduledDate,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{'status': status.value};
      if (scheduledDate != null) {
        body['scheduledDate'] = scheduledDate.toIso8601String();
      }
      
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/vms/$id/training'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// PATCH /admin/vms/:id/mentoring - Update mentoring status
  Future<VMSServiceResponse<Volunteer>> updateMentoringStatus(
    String id, 
    MentoringStatus status,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/vms/$id/mentoring'),
        headers: headers,
        body: json.encode({'status': status.value}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// POST /admin/vms/:id/request-exit - Request exit for a volunteer
  Future<VMSServiceResponse<Volunteer>> requestExit(
    String id, {
    String? reason,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vms/$id/request-exit'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// POST /admin/vms/:id/handover - Complete handover for a mentoring volunteer
  Future<VMSServiceResponse<Volunteer>> completeHandover(
    String id, {
    required String childName,
    String? childStatus,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{
        'childName': childName,
      };
      if (childStatus != null) body['childCurrentStatus'] = childStatus;
      if (notes != null) body['handoverNotes'] = notes;
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vms/$id/handover'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// POST /admin/vms/:id/finalize-exit - Finalize exit for a volunteer
  Future<VMSServiceResponse<Volunteer>> finalizeExit(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vms/$id/finalize-exit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// POST /admin/vms/:id/issue-certificate - Issue certificate to eligible volunteer
  Future<VMSServiceResponse<Volunteer>> issueCertificate(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/vms/$id/issue-certificate'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteer = Volunteer.fromJson(data['volunteer'] ?? data);
        return VMSServiceResponse.success(volunteer);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// GET /admin/vms/export/csv - Export volunteers to CSV
  Future<VMSServiceResponse<String>> exportCSV({
    String? status,
    String? stage,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (stage != null) queryParams['stage'] = stage;
      
      final uri = Uri.parse('$baseUrl/admin/vms/export/csv')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // Return the download URL or CSV content
        final contentType = response.headers['content-type'];
        if (contentType?.contains('text/csv') == true) {
          return VMSServiceResponse.success(response.body);
        }
        final data = json.decode(response.body);
        return VMSServiceResponse.success(data['downloadUrl'] ?? data['url'] ?? response.body);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// Search volunteers by code or name
  Future<VMSServiceResponse<List<Volunteer>>> searchVolunteers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/vms/search?q=${Uri.encodeComponent(query)}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteersJson = data['volunteers'] as List? ?? [];
        final volunteers = volunteersJson
            .map((v) => Volunteer.fromJson(v as Map<String, dynamic>))
            .toList();
        return VMSServiceResponse.success(volunteers);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// Get all volunteers with optional filters
  Future<VMSServiceResponse<List<Volunteer>>> getAllVolunteers({
    String? stage,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{};
      if (stage != null) queryParams['stage'] = stage;
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/admin/volunteers')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final volunteersJson = data['volunteers'] as List? ?? [];
        final volunteers = volunteersJson
            .map((v) => Volunteer.fromJson(v as Map<String, dynamic>))
            .toList();
        return VMSServiceResponse.success(volunteers);
      } else {
        final error = _parseError(response);
        return VMSServiceResponse.error(error);
      }
    } catch (e) {
      return VMSServiceResponse.error('Network error: $e');
    }
  }

  /// Parse error message from response
  String _parseError(http.Response response) {
    try {
      final data = json.decode(response.body);
      return data['message'] ?? data['error'] ?? 'Request failed with status ${response.statusCode}';
    } catch (e) {
      return 'Request failed with status ${response.statusCode}';
    }
  }
}

/// Generic response wrapper for VMS service calls
class VMSServiceResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  VMSServiceResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory VMSServiceResponse.success(T data) {
    return VMSServiceResponse._(data: data, isSuccess: true);
  }

  factory VMSServiceResponse.error(String message) {
    return VMSServiceResponse._(error: message, isSuccess: false);
  }

  /// Execute callback if successful
  void onSuccess(void Function(T data) callback) {
    if (isSuccess && data != null) {
      callback(data as T);
    }
  }

  /// Execute callback if error
  void onError(void Function(String error) callback) {
    if (!isSuccess && error != null) {
      callback(error!);
    }
  }

  /// Map response to another type
  VMSServiceResponse<R> map<R>(R Function(T data) mapper) {
    if (isSuccess && data != null) {
      return VMSServiceResponse.success(mapper(data as T));
    }
    return VMSServiceResponse.error(error ?? 'Unknown error');
  }
}
