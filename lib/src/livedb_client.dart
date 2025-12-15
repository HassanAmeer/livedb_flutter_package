import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/upload_response.dart';
import 'models/token_response.dart';
import 'livedb_config.dart';

import 'live_database.dart';
import 'live_storage.dart';

/// Progress callback type for upload/download operations
typedef ProgressCallback = void Function(double progress, int sent, int total);

/// LiveDB - Realtime Database & Storage Client
class LiveDB {
  static LiveDB? _instance;

  final Dio _dio;
  Dio get dio => _dio; // Public access for sub-modules

  final LiveDBConfig config;
  String? _token;

  // Sub-modules
  late final LiveDatabase db; // Database Access
  late final LiveStorage storage; // Storage Access

  /// Private constructor
  LiveDB._internal(this.config)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.baseUrl,
          connectTimeout: Duration(milliseconds: config.connectTimeout),
          receiveTimeout: Duration(milliseconds: config.receiveTimeout),
          sendTimeout: Duration(milliseconds: config.sendTimeout),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    db = LiveDatabase(this);
    storage = LiveStorage(this);
  }

  /// Get singleton instance with optional custom config
  factory LiveDB([LiveDBConfig? config]) {
    _instance ??= LiveDB._internal(config ?? LiveDBConfig.defaultConfig);
    return _instance!;
  }

  /// Reset instance
  static void reset() {
    _instance = null;
  }

  /// Create a new instance
  static LiveDB create(LiveDBConfig config) {
    return LiveDB._internal(config);
  }

  // ============ Token Management ============

  String? get token => _token;

  void setToken(String token) {
    _token = token;
    _log('✅ Token set successfully');
  }

  Future<String?> generateToken(String email) async {
    try {
      final response = await _dio.post(
        '/api/gen_token',
        data: jsonEncode({'email': email}),
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final data = TokenResponse.fromJson(response.data);
        if (data.success && data.token != null) {
          _token = data.token;
          _log('✅ Token generated: ${_token!.substring(0, 8)}...');
          return _token;
        }
        _log('❌ Token generation failed: ${data.message}');
      }
    } catch (e) {
      _log('❌ Error generating token: $e');
    }
    return null;
  }

  Future<bool> generateAndSetToken(String email) async {
    final token = await generateToken(email);
    return token != null;
  }

  // ============ API Helper ============

  /// Send authenticated request to CloudDB
  Future<dynamic> sendRequest(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (_token == null) {
      throw Exception('Token not set');
    }

    // Generate Cache Key for GET requests if local storage is enabled
    String? cacheKey;
    if (config.enableLocalStorage && method.toUpperCase() == 'GET') {
      final queryString = queryParameters?.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      cacheKey = 'livedb_cache_${path}_${queryString ?? ''}';
    }

    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $_token'},
          contentType: 'application/json',
        ),
      );

      // Save to local storage if GET and enabled
      if (cacheKey != null) {
        _saveToLocal(cacheKey, response.data);
      }

      return response.data;
    } catch (e) {
      _log('❌ Request Failed ($path): ${e.toString()}');

      // Try load from local storage if GET and enabled
      if (cacheKey != null) {
        _log('🔄 Attempting to load from local storage...');
        final cached = await _loadFromLocal(cacheKey);
        if (cached != null) {
          _log('✅ Loaded cached data for: $path');
          return cached;
        } else {
          _log('⚠️ No cached data found for: $path');
        }
      }

      // Provide more specific error info if possible
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception(
            'Connection Timeout: Unable to connect to LiveDB server.',
          );
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception(
            'Network Error: Please check your internet connection.',
          );
        } else if (e.type == DioExceptionType.badResponse) {
          throw Exception(
            'Server Error: ${e.response?.statusCode} - ${e.response?.statusMessage}',
          );
        }
      }

      rethrow;
    }
  }

  Future<void> _saveToLocal(String key, dynamic data) async {
    if (!config.enableLocalStorage) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data));
      _log('💾 Saved to local storage: $key');
    } catch (e) {
      _log('⚠️ Error saving to local storage: $e');
    }
  }

  Future<dynamic> _loadFromLocal(String key) async {
    if (!config.enableLocalStorage) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dataString = prefs.getString(key);
      if (dataString != null) {
        return jsonDecode(dataString);
      }
    } catch (e) {
      _log('⚠️ Error loading from local storage: $e');
    }
    return null;
  }

  // ============ Delegates (Backward Compatibility / Easy Access) ============

  Future<UploadResponse> uploadFile(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return storage.uploadFile(
      file,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  Future<UploadResponse> uploadFileByChunks(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return storage.uploadFileByChunks(
      file,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      chunkSize: chunkSize,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  Future<UploadResponse> uploadByBase64(
    Uint8List bytes, {
    required String fileName,
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return storage.uploadByBase64(
      bytes,
      fileName: fileName,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  Future<UploadResponse> uploadByBase64Chunks(
    Uint8List bytes, {
    required String fileName,
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return storage.uploadByBase64Chunks(
      bytes,
      fileName: fileName,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      chunkSize: chunkSize,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  /// [Deprecated] Use uploadFileByChunks instead
  @Deprecated('Use uploadFileByChunks instead')
  Future<UploadResponse> uploadLargeFile(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return uploadFileByChunks(
      file,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      chunkSize: chunkSize,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  Future<UploadResponse> upload(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) {
    return storage.upload(
      file,
      folderName: folderName,
      deviceName: deviceName,
      isSecret: isSecret,
      dbFolderId: dbFolderId,
      onProgress: onProgress,
    );
  }

  Future<bool> deleteFile(String fileLink) {
    return storage.deleteFile(fileLink);
  }

  void _log(String message) {
    if (config.enableLogging) {
      debugPrint('[LiveDB] $message');
    }
  }
}
