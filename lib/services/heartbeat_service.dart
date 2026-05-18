import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/heartbeat_entry.dart';

class HeartbeatService {
  final String baseUrl = ApiConfig.apiUrl;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Future<bool> createEntry({
    required int hours,
    required String activityType,
    String? activityDetail,
  }) async {
    final token = await secureStorage.read(key: 'token');
    final body = {
      'hoursVolunteered': hours,
      'activityType': activityType,
      if (activityDetail != null) 'activityDetails': activityDetail,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/heartbeat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<HeartbeatEntry>> getMyEntries() async {
    try {
      final token = await secureStorage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$baseUrl/heartbeat/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['entries'] ?? data['data'] ?? [];
          return (list as List)
              .map((e) => HeartbeatEntry.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      print('Error fetching heartbeat entries: $e');
    }
    return [];
  }

  Future<bool> deleteEntry(String id) async {
    final token = await secureStorage.read(key: 'token');
    final response = await http.delete(
      Uri.parse('$baseUrl/heartbeat/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200;
  }

  // Admin APIs (require adminToken in secure storage)
  Future<List<Map<String, dynamic>>> getAdminEntries({
    String? programId,
  }) async {
    try {
      final token = await secureStorage.read(key: 'adminToken');
      final uri = Uri.parse(
        '$baseUrl/heartbeat/admin${programId != null ? '?programId=$programId' : ''}',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final list = data['entries'] ?? data['data'] ?? [];
          return List<Map<String, dynamic>>.from(list as List);
        }
      }
    } catch (e) {
      print('Error fetching admin heartbeat entries: $e');
    }
    return [];
  }

  Future<bool> adminUpdateEntry(String id, Map<String, dynamic> updates) async {
    try {
      final token = await secureStorage.read(key: 'adminToken');
      final response = await http.put(
        Uri.parse('$baseUrl/heartbeat/admin/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating admin heartbeat entry: $e');
      return false;
    }
  }

  Future<bool> adminDeleteEntry(String id) async {
    try {
      final token = await secureStorage.read(key: 'adminToken');
      final response = await http.delete(
        Uri.parse('$baseUrl/heartbeat/admin/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting admin heartbeat entry: $e');
      return false;
    }
  }
}
