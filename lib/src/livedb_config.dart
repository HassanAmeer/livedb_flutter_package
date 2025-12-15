/// Configuration for LiveDB
class LiveDBConfig {
  /// Base URL for API (e.g. https://link.thelocalrent.com)
  final String baseUrl;

  /// Default chunk size for chunked uploads (in bytes)
  /// Default: 1MB (1024 * 1024)
  final int chunkSize;

  /// Connection timeout in milliseconds
  final int connectTimeout;

  /// Receive timeout in milliseconds
  final int receiveTimeout;

  /// Send timeout in milliseconds
  final int sendTimeout;

  /// Enable debug logging
  final bool enableLogging;

  /// Enable local storage caching for offline support
  final bool enableLocalStorage;

  const LiveDBConfig({
    this.baseUrl = 'https://link.thelocalrent.com/api',
    this.chunkSize = 512 * 1024, // 512 KB default
    this.connectTimeout = 30000,
    this.receiveTimeout = 60000,
    this.sendTimeout = 60000,
    this.enableLogging = false,
    this.enableLocalStorage = false,
  });

  /// Default configuration
  static const LiveDBConfig defaultConfig = LiveDBConfig();

  /// Copy with modified values
  LiveDBConfig copyWith({
    String? baseUrl,
    int? chunkSize,
    int? connectTimeout,
    int? receiveTimeout,
    int? sendTimeout,
    bool? enableLogging,
    bool? enableLocalStorage,
  }) {
    return LiveDBConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      chunkSize: chunkSize ?? this.chunkSize,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      enableLocalStorage: enableLocalStorage ?? this.enableLocalStorage,
    );
  }
}
