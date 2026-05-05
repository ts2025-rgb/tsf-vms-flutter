import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/neomami_model.dart';

class NeomamService {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  /// Get authorization token
  Future<String?> _getAuthToken() async {
    try {
      final data = await secureStorage.read(key: "userData");
      if (data != null) {
        final decoded = json.decode(data);
        // Try multiple possible token locations
        String? token = decoded["token"];
        token ??= decoded["user"]?["token"];

        if (token != null) {
          return token;
        }
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    return null;
  }

  /// Create a new Neomami entry
  /// Returns: {success: bool, message: string, data: NeomamEntry or null}
  Future<Map<String, dynamic>> createNeomamEntry(NeomamEntry entry) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/neomam/entries'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(entry.toJson()),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry created successfully',
          'data':
              responseBody['data'] != null
                  ? NeomamEntry.fromJson(responseBody['data'])
                  : null,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not subscribed to the Neomami Hub program',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to create entry',
          'data': null,
        };
      }
    } catch (e) {
      print('Error creating Neomam entry: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'data': null,
      };
    }
  }

  /// Get all Neomami entries for the current volunteer
  /// Returns: {success: bool, message: string, data: List<NeomamEntry> or null}
  Future<Map<String, dynamic>> getVolunteerNeomamEntries() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/neomam/entries'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 304) {
        final entries =
            (responseBody['entries'] as List? ?? responseBody['data'] as List?)
                ?.map((e) => NeomamEntry.fromJson(e))
                .toList() ??
            [];
        return {
          'success': true,
          'message':
              responseBody['message'] ?? 'Entries retrieved successfully',
          'data': entries,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not subscribed to the Neomami Hub program',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to fetch entries',
          'data': null,
        };
      }
    } catch (e) {
      print('Error fetching Neomam entries: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'data': null,
      };
    }
  }

  /// Get a single Neomami entry by ID
  /// Returns: {success: bool, message: string, data: NeomamEntry or null}
  Future<Map<String, dynamic>> getNeomamEntry(String entryId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/neomam/entries/$entryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry retrieved successfully',
          'data':
              responseBody['data'] != null
                  ? NeomamEntry.fromJson(responseBody['data'])
                  : null,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not subscribed to the Neomami Hub program',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to fetch entry',
          'data': null,
        };
      }
    } catch (e) {
      print('Error fetching Neomam entry: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'data': null,
      };
    }
  }

  /// Update a Neomami entry
  /// Returns: {success: bool, message: string, data: NeomamEntry or null}
  Future<Map<String, dynamic>> updateNeomamEntry(
    String entryId,
    NeomamEntry entry,
  ) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.put(
        Uri.parse('$baseUrl/neomam/entries/$entryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(entry.toJson()),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry updated successfully',
          'data':
              responseBody['data'] != null
                  ? NeomamEntry.fromJson(responseBody['data'])
                  : null,
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not subscribed to the Neomami Hub program',
          'data': null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update entry',
          'data': null,
        };
      }
    } catch (e) {
      print('Error updating Neomam entry: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'data': null,
      };
    }
  }

  /// Delete a Neomami entry
  /// Returns: {success: bool, message: string}
  Future<Map<String, dynamic>> deleteNeomamEntry(String entryId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication failed. Please login again.',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/neomam/entries/$entryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry deleted successfully',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not subscribed to the Neomami Hub program',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to delete entry',
        };
      }
    } catch (e) {
      print('Error deleting Neomam entry: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Get admin token from storage
  Future<String?> _getAdminToken() async {
    try {
      final data = await secureStorage.read(key: "adminToken");
      if (data != null) {
        return data;
      }
    } catch (e) {
      print('Error getting admin token: $e');
    }
    return null;
  }

  /// Admin update entry - update any volunteer's entry
  /// Returns: {success: bool, message: string, data: NeomamEntry or null}
  Future<Map<String, dynamic>> adminUpdateNeomamEntry(
    String entryId,
    NeomamEntry entry,
  ) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Admin authentication failed. Please login again.',
          'data': null,
        };
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/neomam/admin/entries/$entryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(entry.toJson()),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry updated successfully',
          'data':
              responseBody['data'] != null
                  ? NeomamEntry.fromJson(responseBody['data'])
                  : null,
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update entry',
          'data': null,
        };
      }
    } catch (e) {
      print('Error updating entry (admin): $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'data': null,
      };
    }
  }

  /// Admin delete entry - delete any volunteer's entry
  /// Returns: {success: bool, message: string}
  Future<Map<String, dynamic>> adminDeleteNeomamEntry(String entryId) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Admin authentication failed. Please login again.',
        };
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/neomam/admin/entries/$entryId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entry deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to delete entry',
        };
      }
    } catch (e) {
      print('Error deleting entry (admin): $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
      };
    }
  }

  /// Get all volunteers with entry counts
  /// Returns: {success: bool, message: string, count: int, volunteers: List}
  Future<Map<String, dynamic>> getVolunteersWithEntryCounts({
    String? search,
    String? sortBy,
  }) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Admin authentication failed. Please login again.',
          'volunteers': [],
        };
      }

      String url = '$baseUrl/neomam/admin/volunteers';
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      if (queryParams.isNotEmpty) {
        url +=
            '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Volunteers retrieved',
          'count': responseBody['count'] ?? 0,
          'volunteers': responseBody['volunteers'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to fetch volunteers',
          'volunteers': [],
        };
      }
    } catch (e) {
      print('Error fetching volunteers: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'volunteers': [],
      };
    }
  }

  /// Get entries for a specific volunteer
  /// Returns: {success: bool, message: string, volunteer: {}, entries: List}
  Future<Map<String, dynamic>> getVolunteerEntries(String volunteerId) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Admin authentication failed. Please login again.',
          'entries': [],
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/neomam/admin/volunteers/$volunteerId/entries'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entries retrieved',
          'volunteer': responseBody['volunteer'],
          'entries': responseBody['entries'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to fetch entries',
          'entries': [],
        };
      }
    } catch (e) {
      print('Error fetching volunteer entries: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'entries': [],
      };
    }
  }

  /// Get filtered entries with pagination
  /// Returns: {success: bool, message: string, count: int, total: int, page: int, pages: int, entries: List}
  Future<Map<String, dynamic>> getFilteredEntries({
    String? volunteerId,
    String? search,
    String? sortBy,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _getAdminToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Admin authentication failed. Please login again.',
          'entries': [],
        };
      }

      String url = '$baseUrl/neomam/admin/entries-filtered';
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (volunteerId != null && volunteerId.isNotEmpty) {
        queryParams['volunteerId'] = volunteerId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }

      url +=
          '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Entries retrieved',
          'count': responseBody['count'] ?? 0,
          'total': responseBody['total'] ?? 0,
          'page': responseBody['page'] ?? 1,
          'pages': responseBody['pages'] ?? 1,
          'entries': responseBody['entries'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to fetch entries',
          'entries': [],
        };
      }
    } catch (e) {
      print('Error fetching filtered entries: $e');
      return {
        'success': false,
        'message': 'Connection error. Please try again.',
        'entries': [],
      };
    }
  }
}
