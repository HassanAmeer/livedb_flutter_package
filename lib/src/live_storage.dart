import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart' hide ProgressCallback;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

import 'livedb_client.dart';
import 'models/upload_response.dart';
import 'models/delete_response.dart';

class LiveStorage {
  final LiveDB _client;

  LiveStorage(this._client);

  bool _checkToken() {
    if (_client.token == null || _client.token!.isEmpty) {
      _log('❌ Token not set.');
      return false;
    }
    return true;
  }

  String _sanitizeFolderName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _generateFileId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}_${now.microsecond}';
  }

  void _log(String message) {
    if (_client.config.enableLogging) {
      debugPrint('[LiveStorage] $message');
    }
  }

  /// Get auth headers with Bearer token
  Map<String, String> _getAuthHeaders() {
    if (_client.token != null && _client.token!.isNotEmpty) {
      return {'Authorization': 'Bearer ${_client.token}'};
    }
    return {};
  }

  /// Upload a file using multipart form data
  Future<UploadResponse> uploadFile(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    if (!_checkToken()) {
      return UploadResponse(success: false, message: 'Token not set.');
    }
    if (!await file.exists()) {
      return UploadResponse(success: false, message: 'File not found');
    }

    try {
      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      final formData = FormData.fromMap({
        'folder_name': _sanitizeFolderName(folderName),
        'is_secret': isSecret ? '1' : '0',
        'from_device_name': deviceName,
        if (dbFolderId != null) 'db_folder_id': dbFolderId,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _client.dio.post(
        '/api/upload_file',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: _getAuthHeaders(),
        ),
        onSendProgress: (sent, total) =>
            onProgress?.call(sent / total, sent, total),
      );

      if (response.statusCode == 200) {
        final data = UploadResponse.fromJson(response.data);
        if (data.success) _log('✅ Uploaded: ${data.link}');
        return data;
      }
      return UploadResponse(
        success: false,
        message: 'Status: ${response.statusCode}',
      );
    } catch (e) {
      _log('❌ Error: $e');
      return UploadResponse(success: false, message: 'Error: $e');
    }
  }

  /// Upload file from bytes (Base64)
  Future<UploadResponse> uploadByBase64(
    Uint8List bytes, {
    required String fileName,
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    if (!_checkToken()) {
      return UploadResponse(success: false, message: 'Token not set');
    }

    try {
      final base64String = base64Encode(bytes);
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      final base64WithPrefix = 'data:$mimeType;base64,$base64String';

      final body = {
        'folder_name': _sanitizeFolderName(folderName),
        'is_secret': isSecret,
        'file_base64': base64WithPrefix,
        if (dbFolderId != null) 'db_folder_id': dbFolderId,
      };

      final response = await _client.dio.post(
        '/api/upload_base64',
        data: jsonEncode(body),
        options: Options(
          contentType: 'application/json',
          headers: _getAuthHeaders(),
        ),
        onSendProgress: (sent, total) =>
            onProgress?.call(sent / total, sent, total),
      );

      if (response.statusCode == 200) {
        final data = UploadResponse.fromJson(response.data);
        if (data.success) _log('✅ Uploaded (Base64): ${data.link}');
        return data;
      }
      return UploadResponse(
        success: false,
        message: 'Status: ${response.statusCode}',
      );
    } catch (e) {
      _log('❌ Error: $e');
      return UploadResponse(success: false, message: 'Error: $e');
    }
  }

  /// Upload large file in chunks (File)
  Future<UploadResponse> uploadFileByChunks(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    if (!_checkToken()) {
      return UploadResponse(success: false, message: 'Token not set.');
    }
    if (!await file.exists()) {
      return UploadResponse(success: false, message: 'File not found');
    }

    try {
      final bytes = await file.readAsBytes();
      return _uploadBytesByChunks(
        bytes,
        fileName: path.basename(file.path),
        folderName: folderName,
        deviceName: deviceName,
        isSecret: isSecret,
        chunkSize: chunkSize,
        dbFolderId: dbFolderId,
        onProgress: onProgress,
      );
    } catch (e) {
      _log('❌ Chunked Error: $e');
      return UploadResponse(success: false, message: 'Error: $e');
    }
  }

  /// Upload bytes in chunks (Base64/Uint8List)
  Future<UploadResponse> uploadByBase64Chunks(
    Uint8List bytes, {
    required String fileName,
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    if (!_checkToken()) {
      return UploadResponse(success: false, message: 'Token not set.');
    }

    try {
      return _uploadBytesByChunks(
        bytes,
        fileName: fileName,
        folderName: folderName,
        deviceName: deviceName,
        isSecret: isSecret,
        chunkSize: chunkSize,
        dbFolderId: dbFolderId,
        onProgress: onProgress,
      );
    } catch (e) {
      _log('❌ Chunked Base64 Error: $e');
      return UploadResponse(success: false, message: 'Error: $e');
    }
  }

  /// Internal helper to upload bytes in chunks
  Future<UploadResponse> _uploadBytesByChunks(
    Uint8List bytes, {
    required String fileName,
    required String folderName,
    required String deviceName,
    required bool isSecret,
    int? chunkSize,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    final effectiveChunkSize = chunkSize ?? _client.config.chunkSize;
    final totalChunks = (bytes.length / effectiveChunkSize).ceil();
    final fileId = _generateFileId();

    _log('📦 Starting chunked upload for \$fileName: \$totalChunks chunks');

    UploadResponse? lastResponse;

    for (int i = 0; i < totalChunks; i++) {
      final start = i * effectiveChunkSize;
      final end = (start + effectiveChunkSize > bytes.length)
          ? bytes.length
          : start + effectiveChunkSize;
      final chunk = bytes.sublist(start, end);

      final formData = FormData.fromMap({
        'folder_name': _sanitizeFolderName(folderName),
        'is_secret': isSecret ? '1' : '0',
        'file_id': fileId,
        'chunk_index': i,
        'total_chunks': totalChunks,
        if (dbFolderId != null) 'db_folder_id': dbFolderId,
        'chunk_file': MultipartFile.fromBytes(chunk, filename: 'chunk_\$i'),
      });

      final response = await _client.dio.post(
        '/api/upload_file_chunks',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: _getAuthHeaders(),
        ),
      );

      if (response.statusCode == 200) {
        lastResponse = UploadResponse.fromJson(response.data);
        final overallProgress = (i + 1) / totalChunks;
        onProgress?.call(overallProgress, end, bytes.length);
        _log('📤 Chunk \${i + 1}/\$totalChunks uploaded');
      } else {
        return UploadResponse(
          success: false,
          message: 'Chunk \$i failed: \${response.statusCode}',
        );
      }
    }

    if (lastResponse?.success == true) {
      _log('✅ Large file uploaded: \${lastResponse!.link}');
    }
    return lastResponse ??
        UploadResponse(success: false, message: 'Upload failed');
  }

  /// Smart upload - chooses method based on size
  Future<UploadResponse> upload(
    File file, {
    String folderName = 'uploads',
    String deviceName = 'flutter_app',
    bool isSecret = false,
    int? dbFolderId,
    ProgressCallback? onProgress,
  }) async {
    final stat = await file.stat();
    const fiveMB = 5 * 1024 * 1024;

    if (stat.size >= fiveMB) {
      _log(
        '📁 Using chunked upload for ${(stat.size / 1024 / 1024).toStringAsFixed(2)} MB file',
      );
      return uploadFileByChunks(
        file,
        folderName: folderName,
        deviceName: deviceName,
        isSecret: isSecret,
        chunkSize: null, // use default
        dbFolderId: dbFolderId,
        onProgress: onProgress,
      );
    } else {
      _log('📁 Using direct upload for small file');
      return uploadFile(
        file,
        folderName: folderName,
        deviceName: deviceName,
        isSecret: isSecret,
        dbFolderId: dbFolderId,
        onProgress: onProgress,
      );
    }
  }

  // Delete file
  Future<bool> deleteFile(String fileLink) async {
    if (!_checkToken()) {
      _log('❌ Token required for delete operation');
      return false;
    }

    try {
      final response = await _client.dio.post(
        '/api/deletefile',
        data: jsonEncode({'filelink': fileLink}),
        options: Options(
          contentType: 'application/json',
          headers: _getAuthHeaders(),
        ),
      );
      if (response.statusCode == 200) {
        final data = DeleteResponse.fromJson(response.data);
        if (data.success) return true;
      }
    } catch (e) {
      _log('❌ Delete error: $e');
    }
    return false;
  }
}
