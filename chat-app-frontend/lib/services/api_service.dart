import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_constants.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/message.dart';
import 'api_exception.dart';
import 'log_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'Unknown error',
      data: fromJsonT != null && json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}

class ApiService {
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Map<String, String> _headers({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic) fromJson,
  ) async {
    LogService.info('API Response: ${response.statusCode} ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final body = jsonDecode(response.body);
        final apiResponse = ApiResponse.fromJson(body, fromJson);
        
        if (apiResponse.success && apiResponse.data != null) {
          return apiResponse.data!;
        } else {
           // Sometimes success is true but data is null (e.g. void response), handle if needed
           if(apiResponse.success) {
             // If T is void or nullable, this might be tricky. 
             // For now assuming all our successful responses have data or we handle it.
             // If data is null but success is true, we might need to return null if T allows it.
             // But our signature is Future<T>, so T must be returned.
             // Let's assume for now data is there.
             return apiResponse.data as T;
           }
           throw ApiException(apiResponse.message, statusCode: response.statusCode);
        }
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException('Failed to parse response: $e', statusCode: response.statusCode);
      }
    } else {
      String message = 'Request failed';
      try {
        final body = jsonDecode(response.body);
        message = body['message'] ?? message;
      } catch (_) {}
      
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  // Auth APIs
  static Future<AuthResponse> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    LogService.info('Signing up user: $email');
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.signup}'),
      headers: _headers(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      }),
    );

    return _handleResponse(response, (data) {
        final authResponse = AuthResponse.fromJson(data);
        setToken(authResponse.token);
        return authResponse;
    });
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    LogService.info('Logging in user: $email');
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: _headers(includeAuth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response, (data) {
      final authResponse = AuthResponse.fromJson(data);
      setToken(authResponse.token);
      return authResponse;
    });
  }

  static Future<User> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated', statusCode: 401);

    LogService.info('Fetching current user');
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}'),
      headers: _headers(),
    );

    return _handleResponse(response, (data) => User.fromJson(data));
  }

  // Room APIs
  static Future<List<Room>> getRooms() async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated', statusCode: 401);

    LogService.info('Fetching rooms');
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rooms}'),
      headers: _headers(),
    );

    return _handleResponse(response, (data) => (data as List).map((room) => Room.fromJson(room)).toList());
  }

  static Future<Room> createRoom({
    required String name,
    String description = '',
    required List<String> participantEmails,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated', statusCode: 401);

    LogService.info('Creating room: $name');
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rooms}'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'participantEmails': participantEmails,
      }),
    );

    return _handleResponse(response, (data) => Room.fromJson(data));
  }

  static Future<List<Message>> getRoomMessages({
    required String roomId,
    int page = 0,
    int size = 100,
  }) async {
    final token = await getToken();
    if (token == null) throw ApiException('Not authenticated', statusCode: 401);

    LogService.info('Fetching messages for room: $roomId');
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.rooms}/$roomId/messages',
    ).replace(queryParameters: {
      'page': page.toString(),
      'size': size.toString(),
    });

    final response = await http.get(
      uri,
      headers: _headers(),
    );

    return _handleResponse(response, (data) {
      final content = data['content'] as List;
      return content.map((msg) => Message.fromJson(msg)).toList();
    });
  }
  
  // Send message via REST API (alternative to WebSocket)
  // static Future<ChatMessageResponse> sendMessage({
  //   required String roomId,
  //   required String content,
  //   String messageType = 'TEXT',
  //   Map<String, dynamic>? media,
  // }) async {
  //   final token = await getToken();
  //   if (token == null) throw ApiException('Not authenticated', statusCode: 401);
  //
  //   LogService.info('Sending message to room: $roomId');
  //   final  Map<String, dynamic> body = {
  //     'content': content,
  //     'messageType': messageType,
  //   };
  //
  //   if (media != null) {
  //     body['media'] = media;
  //   }
  //
  //   final response = await http.post(
  //     Uri.parse('${ApiConstants.baseUrl}${ApiConstants.roomMessages(roomId)}'),
  //     headers: _headers(),
  //     body: jsonEncode(body),
  //   );
  //
  //   return _handleResponse(response, (data) => ChatMessageResponse.fromJson(data));
  // }
}

