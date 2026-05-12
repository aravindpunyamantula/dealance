import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Central API client for Dealance backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  Dio? _dioInstance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';

  /// Lazy Dio initialization — ensures dotenv is loaded before creating Dio
  Dio get _dio {
    _dioInstance ??= _createDio();
    return _dioInstance!;
  }

  ApiService._internal();

  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          try {
            final newTokens = await _refreshToken();
            if (newTokens != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${newTokens['accessToken']}';
              final response = await _dio.fetch(opts);
              return handler.resolve(response);
            }
          } catch (_) {}
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  Future<Map<String, dynamic>?> _refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      final response = await Dio(BaseOptions(baseUrl: baseUrl))
          .post('/auth/refresh', data: {'refreshToken': refreshToken});
      final tokens = response.data;
      await _storage.write(key: 'access_token', value: tokens['accessToken']);
      await _storage.write(key: 'refresh_token', value: tokens['refreshToken']);
      return tokens;
    } catch (_) {
      await clearTokens();
      return null;
    }
  }

  // ─── Token Management ───

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_data');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  // ─── Auth Endpoints (OTP) ───

  Future<Map<String, dynamic>> sendOtp({required String email}) async {
    final response = await _dio.post('/auth/send-otp', data: {'email': email});
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    String? name,
    String? role,
    String? phone,
    String? linkedIn,
    String? education,
    String? networth,
  }) async {
    final data = <String, dynamic>{'email': email, 'code': code};
    if (name != null && name.isNotEmpty) data['name'] = name;
    if (role != null && role.isNotEmpty) data['role'] = role;
    if (phone != null && phone.isNotEmpty) data['phone'] = phone;
    if (linkedIn != null && linkedIn.isNotEmpty) data['linkedIn'] = linkedIn;
    if (education != null && education.isNotEmpty) data['education'] = education;
    if (networth != null && networth.isNotEmpty) data['networth'] = networth;
    final response = await _dio.post('/auth/verify-otp', data: data);
    return response.data;
  }

  // ─── Auth: Google OAuth ───

  Future<Map<String, dynamic>> googleSignIn({required String idToken}) async {
    final response = await _dio.post('/auth/google', data: {'idToken': idToken});
    return response.data;
  }

  // ─── User Endpoints ───

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/user/profile');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/user/profile', data: data);
    return response.data;
  }

  // ─── Idea Endpoints (Entrepreneur) ───

  Future<List<dynamic>> getMyIdeas() async {
    final response = await _dio.get('/ideas');
    return response.data;
  }

  Future<Map<String, dynamic>> createIdea(Map<String, dynamic> data) async {
    final response = await _dio.post('/ideas', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getIdea(String ideaId) async {
    final response = await _dio.get('/ideas/$ideaId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateIdeaStep(
    String ideaId, int stepNumber, Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/ideas/$ideaId/step/$stepNumber', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> submitIdea(String ideaId) async {
    final response = await _dio.post('/ideas/$ideaId/submit');
    return response.data;
  }

  Future<void> deleteIdea(String ideaId) async {
    await _dio.delete('/ideas/$ideaId');
  }

  // ─── AI Endpoints ───

  Future<Map<String, dynamic>> triggerAIAnalysis(String ideaId) async {
    final response = await _dio.post('/ai/analyze/$ideaId');
    return response.data;
  }

  Future<Map<String, dynamic>> getAIReport(String ideaId) async {
    final response = await _dio.get('/ai/report/$ideaId');
    return response.data;
  }

  Future<String> getInvestorAIReview(String ideaId) async {
    final response = await _dio.get('/ai/investor-review/$ideaId');
    return response.data['report'] ?? 'No report generated.';
  }

  // ─── Learning Endpoints ───

  Future<List<dynamic>> getArticles({String? type, String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;

    final response = await _dio.get('/learn/articles', queryParameters: queryParams);
    return response.data;
  }

  // ─── Upload Endpoints ───

  Future<Map<String, dynamic>> uploadFile(File file, {String folder = 'uploads'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      'folder': folder,
    });
    final response = await _dio.post('/upload', data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> uploadXFile(XFile file, {String folder = 'uploads'}) async {
    MultipartFile multipartFile;
    if (kIsWeb) {
      multipartFile = MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name);
    } else {
      multipartFile = await MultipartFile.fromFile(file.path, filename: file.name);
    }
    
    final formData = FormData.fromMap({
      'file': multipartFile,
      'folder': folder,
    });
    final response = await _dio.post('/upload', data: formData);
    return response.data;
  }

  // ─── Notification Endpoints ───

  Future<List<dynamic>> getNotifications() async {
    final response = await _dio.get('/user/notifications');
    return response.data;
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _dio.put('/user/notifications/$notificationId/read');
  }

  // ─── Investor Feed Endpoints ───

  Future<List<dynamic>> getDealFlowFeed() async {
    final response = await _dio.get('/feed');
    return response.data;
  }

  Future<Map<String, dynamic>> getIdeaForInvestor(String ideaId) async {
    final response = await _dio.get('/feed/$ideaId');
    return response.data;
  }

  // ─── NDA Endpoints ───

  Future<Map<String, dynamic>> signNDA({
    required String ideaId,
    required String signatureText,
  }) async {
    final response = await _dio.post('/nda/sign', data: {
      'ideaId': ideaId,
      'signatureText': signatureText,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> checkNDA(String ideaId) async {
    final response = await _dio.get('/nda/check/$ideaId');
    return response.data;
  }

  // ─── Investor Directory Endpoints ───

  Future<List<dynamic>> searchInvestors({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final response = await _dio.get('/investors', queryParameters: queryParams);
    return response.data;
  }

  Future<Map<String, dynamic>> inviteInvestor({
    required String ideaId,
    required String investorId,
  }) async {
    final response = await _dio.post('/investors/invite', data: {
      'ideaId': ideaId,
      'investorId': investorId,
    });
    return response.data;
  }

  Future<List<dynamic>> getInvitedInvestors(String ideaId) async {
    final response = await _dio.get('/investors/invited/$ideaId');
    return response.data;
  }

  // ─── Social Feed (Posts) ───

  Future<List<dynamic>> getFeedPosts({int page = 1}) async {
    final response = await _dio.get('/posts', queryParameters: {'page': page.toString()});
    return response.data;
  }

  Future<List<dynamic>> getMyPosts(String authorId, {int page = 1}) async {
    final response = await _dio.get('/posts', queryParameters: {'authorId': authorId, 'page': page.toString()});
    return response.data;
  }

  Future<Map<String, dynamic>> createPost({required String content, String? startupId, List<String>? mediaUrls}) async {
    final response = await _dio.post('/posts', data: {
      'content': content,
      if (startupId != null) 'startupId': startupId,
      if (mediaUrls != null) 'mediaUrls': mediaUrls,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _dio.post('/posts/$postId/like');
    return response.data;
  }

  Future<List<dynamic>> getComments(String postId) async {
    final response = await _dio.get('/posts/$postId/comments');
    return response.data;
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    final response = await _dio.post('/posts/$postId/comments', data: {'content': content});
    return response.data;
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete('/posts/$postId');
  }

  // ─── Chat ───

  Future<List<dynamic>> getChatRooms() async {
    final response = await _dio.get('/chat/rooms');
    return response.data;
  }

  Future<Map<String, dynamic>> getOrCreateDMRoom(String otherUserId) async {
    final response = await _dio.post('/chat/rooms', data: {'otherUserId': otherUserId});
    return response.data;
  }

  Future<List<dynamic>> getChatMessages(String roomId, {int page = 1}) async {
    final response = await _dio.get('/chat/rooms/$roomId/messages', queryParameters: {'page': page.toString()});
    return response.data;
  }

  Future<Map<String, dynamic>> sendChatMessage(String roomId, String content, {String type = 'TEXT'}) async {
    final response = await _dio.post('/chat/rooms/$roomId/messages', data: {'content': content, 'type': type});
    return response.data;
  }

  // ─── Deals ───

  Future<Map<String, dynamic>> createDeal(Map<String, dynamic> data) async {
    final response = await _dio.post('/deals', data: data);
    return response.data;
  }

  Future<List<dynamic>> getMyDeals() async {
    final response = await _dio.get('/deals');
    return response.data;
  }

  Future<Map<String, dynamic>> getDeal(String dealId) async {
    final response = await _dio.get('/deals/$dealId');
    return response.data;
  }

  Future<Map<String, dynamic>> updateDeal(String dealId, Map<String, dynamic> data) async {
    final response = await _dio.put('/deals/$dealId', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> acceptDeal(String dealId) async {
    final response = await _dio.put('/deals/$dealId/accept');
    return response.data;
  }

  Future<Map<String, dynamic>> rejectDeal(String dealId) async {
    final response = await _dio.put('/deals/$dealId/reject');
    return response.data;
  }

  // ─── Role Selection ───

  Future<Map<String, dynamic>> completeSignup({required String name, required String role}) async {
    final response = await _dio.post('/auth/complete-signup', data: {'name': name, 'role': role});
    return response.data;
  }

  // ─── Public Profile ───

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _dio.get('/users/$userId/profile');
    return response.data;
  }
}
