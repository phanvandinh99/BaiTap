import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:7001/api';
    } else {
      return 'http://10.0.2.2:7001/api';
    }
  }

  // SharedPreferences instance
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Get current user ID from storage
  static Future<int?> getCurrentUserId() async {
    final prefs = await _prefs;
    return prefs.getInt('userId');
  }

  // Set current user ID
  static Future<void> setCurrentUserId(int userId) async {
    final prefs = await _prefs;
    await prefs.setInt('userId', userId);
  }

  // Get current user role
  static Future<String?> getCurrentUserRole() async {
    final prefs = await _prefs;
    return prefs.getString('userRole');
  }

  // Set current user role
  static Future<void> setCurrentUserRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString('userRole', role);
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'ADMIN';
  }

  // Clear session
  static Future<void> logout() async {
    final prefs = await _prefs;
    await prefs.remove('userId');
    await prefs.remove('userRole');
  }

  // Helper to get headers with user ID and admin flag
  Future<Map<String, String>> _getHeaders({bool isAdmin = false}) async {
    final userId = await getCurrentUserId();
    // Auto-detect admin if not explicitly set
    if (!isAdmin) {
      isAdmin = await ApiService.isAdmin();
    }
    return {
      'Content-Type': 'application/json',
      if (userId != null) 'X-User-Id': userId.toString(),
      if (isAdmin) 'X-Admin': 'true',
    };
  }

  // User APIs
  Future<Map<String, dynamic>> register(String username, String email, String password, String fullName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );
    if (response.statusCode == 200) {
      final user = json.decode(response.body);
      await setCurrentUserId(user['id']);
      // Save user role for admin check
      if (user['role'] != null) {
        await setCurrentUserRole(user['role']);
      }
      return user;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getUser(int id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/users/$id'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user');
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
      body: json.encode(updates),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
  }

  // Admin: Get all users
  Future<List<dynamic>> getAllUsers() async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Admin: Deactivate user
  Future<void> deactivateUser(int id) async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to deactivate user');
    }
  }

  // Admin: Get all users
  Future<List<dynamic>> getAllUsers() async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data is List ? data : [];
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Admin: Deactivate user
  Future<void> deactivateUser(int id) async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.delete(Uri.parse('$baseUrl/users/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to deactivate user');
    }
  }

  // Question APIs (existing)
  Future<List<dynamic>> getQuestions({int page = 1, int pageSize = 20, String? search, int? topicId}) async {
    final queryParams = {
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (search != null) 'search': search,
      if (topicId != null) 'topicId': topicId.toString(),
    };
    final uri = Uri.parse('$baseUrl/questions').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> createQuestion(String title, String content, int topicId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/questions'),
      headers: headers,
      body: json.encode({
        'title': title,
        'content': content,
        'topicId': topicId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create question');
    }
  }

  Future<Map<String, dynamic>> getQuestion(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/questions/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get question');
    }
  }

  Future<void> updateQuestion(int id, Map<String, dynamic> updates) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/questions/$id'),
      headers: headers,
      body: json.encode(updates),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update question');
    }
  }

  Future<void> deleteQuestion(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/questions/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete question');
    }
  }

  Future<void> changeQuestionStatus(int id, String status) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/questions/$id/status'),
      headers: headers,
      body: json.encode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change status');
    }
  }

  // Answer APIs
  Future<List<dynamic>> getAnswers(int questionId) async {
    final response = await http.get(Uri.parse('$baseUrl/questions/$questionId/answers'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load answers');
    }
  }

  Future<void> createAnswer(int questionId, String content) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/questions/$questionId/answers'),
      headers: headers,
      body: json.encode({'content': content}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create answer');
    }
  }

  Future<void> updateAnswer(int id, String content) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/answers/$id'),
      headers: headers,
      body: json.encode({'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update answer');
    }
  }

  Future<void> deleteAnswer(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/answers/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete answer');
    }
  }

  Future<void> acceptAnswer(int id) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/answers/$id/accept'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to accept answer');
    }
  }

  // Comment APIs
  Future<List<dynamic>> getComments(String targetType, int targetId) async {
    final queryParams = {'targetType': targetType, 'targetId': targetId.toString()};
    final uri = Uri.parse('$baseUrl/comments').replace(queryParameters: queryParams);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<void> createComment(String targetType, int targetId, String content) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/comments'),
      headers: headers,
      body: json.encode({
        'targetType': targetType,
        'targetId': targetId,
        'content': content,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create comment');
    }
  }

  Future<void> updateComment(int id, String content) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/comments/$id'),
      headers: headers,
      body: json.encode({'content': content}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update comment');
    }
  }

  Future<void> deleteComment(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/comments/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete comment');
    }
  }

  // Vote APIs
  Future<Map<String, dynamic>> getVoteInfo(String targetType, int targetId) async {
    final headers = await _getHeaders();
    final queryParams = {'targetType': targetType, 'targetId': targetId.toString()};
    final uri = Uri.parse('$baseUrl/votes').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get vote info');
    }
  }

  Future<void> vote(String targetType, int targetId, String voteType) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/votes'),
      headers: headers,
      body: json.encode({
        'targetType': targetType,
        'targetId': targetId,
        'voteType': voteType,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to vote');
    }
  }

  Future<void> removeVote(String targetType, int targetId) async {
    final headers = await _getHeaders();
    final queryParams = {'targetType': targetType, 'targetId': targetId.toString()};
    final uri = Uri.parse('$baseUrl/votes').replace(queryParameters: queryParams);
    final response = await http.delete(uri, headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to remove vote');
    }
  }

  // Notification APIs
  Future<Map<String, dynamic>> getNotifications({int limit = 50}) async {
    final headers = await _getHeaders();
    final queryParams = {'limit': limit.toString()};
    final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/notifications/read/$id'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark as read');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/notifications/read-all'), headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all as read');
    }
  }

  Future<void> deleteNotification(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/notifications/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete notification');
    }
  }

  // Topic APIs
  Future<List<dynamic>> getTopics() async {
    final response = await http.get(Uri.parse('$baseUrl/topics'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load topics');
    }
  }

  Future<Map<String, dynamic>> getTopic(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/topics/$id'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get topic');
    }
  }

  Future<void> createTopic(String name, String slug, String? description) async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.post(
      Uri.parse('$baseUrl/topics'),
      headers: headers,
      body: json.encode({
        'name': name,
        'slug': slug,
        'description': description,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create topic: ${response.body}');
    }
  }

  Future<void> updateTopic(int id, String name, String slug, String? description) async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.put(
      Uri.parse('$baseUrl/topics/$id'),
      headers: headers,
      body: json.encode({
        'name': name,
        'slug': slug,
        'description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update topic: ${response.body}');
    }
  }

  Future<void> deleteTopic(int id) async {
    final headers = await _getHeaders(isAdmin: true);
    final response = await http.delete(Uri.parse('$baseUrl/topics/$id'), headers: headers);
    if (response.statusCode != 204) {
      throw Exception('Failed to delete topic: ${response.body}');
    }
  }
}