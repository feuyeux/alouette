import 'dart:async';
import 'dart:collection';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';
import '../../exceptions/tts_exception.dart';

/// Connection pool for managing WebSocket connections to Edge TTS
class EdgeTTSConnectionPool {
  static const int _defaultMaxConnections = 5;
  static const Duration _defaultConnectionTimeout = Duration(seconds: 30);
  static const Duration _defaultIdleTimeout = Duration(minutes: 5);
  static const String _edgeTTSUrl =
      'wss://speech.platform.bing.com/consumer/speech/synthesize/realtimestreaming/edge/v1';
  static const String _trustedClientToken = '6A5AA1D4EAFF4E9FB37E23D68491D6F4';

  final int _maxConnections;
  final Duration _connectionTimeout;
  final Duration _idleTimeout;

  final Queue<_PooledConnection> _availableConnections =
      Queue<_PooledConnection>();
  final Set<_PooledConnection> _activeConnections = <_PooledConnection>{};
  final Map<String, Completer<_PooledConnection>> _pendingRequests = {};

  Timer? _cleanupTimer;
  bool _disposed = false;

  EdgeTTSConnectionPool({
    int maxConnections = _defaultMaxConnections,
    Duration connectionTimeout = _defaultConnectionTimeout,
    Duration idleTimeout = _defaultIdleTimeout,
  })  : _maxConnections = maxConnections,
        _connectionTimeout = connectionTimeout,
        _idleTimeout = idleTimeout {
    // Start periodic cleanup of idle connections
    _cleanupTimer = Timer.periodic(
        const Duration(minutes: 1), (_) => _cleanupIdleConnections());
  }

  /// Gets a connection from the pool or creates a new one
  Future<_PooledConnection> getConnection() async {
    if (_disposed) {
      throw TTSException('Connection pool has been disposed');
    }

    // Try to get an available connection first
    if (_availableConnections.isNotEmpty) {
      final connection = _availableConnections.removeFirst();
      if (connection.isHealthy) {
        _activeConnections.add(connection);
        connection._markActive();
        return connection;
      } else {
        // Connection is not healthy, dispose it
        await connection._dispose();
      }
    }

    // Create new connection if under limit
    if (_getTotalConnections() < _maxConnections) {
      try {
        final connection = await _createConnection();
        _activeConnections.add(connection);
        return connection;
      } catch (e) {
        throw TTSNetworkException(
          'Failed to create new connection: $e',
          endpoint: _edgeTTSUrl,
        );
      }
    }

    // Wait for a connection to become available
    final requestId = const Uuid().v4();
    final completer = Completer<_PooledConnection>();
    _pendingRequests[requestId] = completer;

    // Set timeout for waiting
    Timer(_connectionTimeout, () {
      if (!completer.isCompleted) {
        _pendingRequests.remove(requestId);
        completer.completeError(
          TTSNetworkException(
            'Timeout waiting for available connection',
            endpoint: _edgeTTSUrl,
          ),
        );
      }
    });

    return completer.future;
  }

  /// Returns a connection to the pool
  void returnConnection(_PooledConnection connection) {
    if (_disposed) {
      connection._dispose();
      return;
    }

    _activeConnections.remove(connection);

    if (connection.isHealthy) {
      connection._markIdle();
      _availableConnections.add(connection);

      // Fulfill pending requests
      if (_pendingRequests.isNotEmpty) {
        final requestId = _pendingRequests.keys.first;
        final completer = _pendingRequests.remove(requestId)!;

        final returnedConnection = _availableConnections.removeFirst();
        _activeConnections.add(returnedConnection);
        returnedConnection._markActive();

        completer.complete(returnedConnection);
      }
    } else {
      // Connection is not healthy, dispose it
      connection._dispose();
    }
  }

  /// Creates a new WebSocket connection
  Future<_PooledConnection> _createConnection() async {
    final connectionId = const Uuid().v4();
    final uri = Uri.parse(_edgeTTSUrl).replace(queryParameters: {
      'TrustedClientToken': _trustedClientToken,
      'ConnectionId': connectionId,
    });

    try {
      final channel = WebSocketChannel.connect(uri);
      final connection = _PooledConnection(
        channel: channel,
        id: connectionId,
        pool: this,
      );

      // Send initial configuration
      try {
        await connection._initialize();
      } catch (e) {
        // If initialization fails, dispose the connection and rethrow
        await connection._dispose();
        throw TTSNetworkException(
          'Failed to initialize connection: $e',
          endpoint: _edgeTTSUrl,
        );
      }

      return connection;
    } catch (e) {
      throw TTSNetworkException(
        'Failed to establish WebSocket connection: $e',
        endpoint: _edgeTTSUrl,
      );
    }
  }

  /// Cleans up idle connections that have exceeded the idle timeout
  void _cleanupIdleConnections() {
    if (_disposed) return;

    final now = DateTime.now();
    final connectionsToRemove = <_PooledConnection>[];

    for (final connection in _availableConnections) {
      if (now.difference(connection._lastUsed) > _idleTimeout) {
        connectionsToRemove.add(connection);
      }
    }

    for (final connection in connectionsToRemove) {
      _availableConnections.remove(connection);
      connection._dispose();
    }
  }

  /// Gets the total number of connections (active + available)
  int _getTotalConnections() {
    return _activeConnections.length + _availableConnections.length;
  }

  /// Gets pool statistics
  Map<String, dynamic> getPoolStats() {
    return {
      'maxConnections': _maxConnections,
      'totalConnections': _getTotalConnections(),
      'activeConnections': _activeConnections.length,
      'availableConnections': _availableConnections.length,
      'pendingRequests': _pendingRequests.length,
      'connectionTimeoutSeconds': _connectionTimeout.inSeconds,
      'idleTimeoutMinutes': _idleTimeout.inMinutes,
    };
  }

  /// Disposes of the connection pool and all connections
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    _cleanupTimer?.cancel();

    // Complete pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          TTSException('Connection pool disposed'),
        );
      }
    }
    _pendingRequests.clear();

    // Dispose all connections
    final allConnections = [..._activeConnections, ..._availableConnections];
    _activeConnections.clear();
    _availableConnections.clear();

    for (final connection in allConnections) {
      await connection._dispose();
    }
  }
}

/// A pooled WebSocket connection with lifecycle management
class _PooledConnection {
  final WebSocketChannel channel;
  final String id;
  final EdgeTTSConnectionPool pool;

  DateTime _lastUsedTime = DateTime.now();
  bool _isActive = false;
  bool _disposed = false;

  _PooledConnection({
    required this.channel,
    required this.id,
    required this.pool,
  });

  /// Checks if the connection is healthy
  bool get isHealthy {
    return !_disposed && channel.closeCode == null;
  }

  /// Gets the last used timestamp
  DateTime get _lastUsed => _lastUsedTime;

  /// Initializes the connection with Edge TTS configuration
  Future<void> _initialize() async {
    final configMessage =
        'X-Timestamp:${DateTime.now().toUtc().toIso8601String()}\r\n'
        'Content-Type:application/json; charset=utf-8\r\n'
        'Path:speech.config\r\n\r\n'
        '{"context":{"synthesis":{"audio":{"metadataoptions":{"sentenceBoundaryEnabled":"false","wordBoundaryEnabled":"true"},"outputFormat":"audio-24khz-48kbitrate-mono-mp3"}}}}';

    channel.sink.add(configMessage);
  }

  /// Marks the connection as active
  void _markActive() {
    _isActive = true;
    _lastUsedTime = DateTime.now();
  }

  /// Marks the connection as idle
  void _markIdle() {
    _isActive = false;
    _lastUsedTime = DateTime.now();
  }

  /// Sends a synthesis request through this connection
  Future<void> sendSynthesisRequest(String ssml) async {
    if (_disposed || !isHealthy) {
      throw TTSException('Connection is not available');
    }

    final requestId = const Uuid().v4();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    final synthesisMessage = 'X-RequestId:$requestId\r\n'
        'X-Timestamp:$timestamp\r\n'
        'Content-Type:application/ssml+xml\r\n'
        'Path:ssml\r\n\r\n'
        '$ssml';

    channel.sink.add(synthesisMessage);
    _markActive();
  }

  /// Returns this connection to the pool
  void returnToPool() {
    if (!_disposed) {
      pool.returnConnection(this);
    }
  }

  /// Disposes of this connection
  Future<void> _dispose() async {
    if (_disposed) return;

    _disposed = true;
    try {
      await channel.sink.close();
    } catch (e) {
      // Ignore errors during disposal
    }
  }

  /// Gets connection statistics
  Map<String, dynamic> getConnectionStats() {
    return {
      'id': id,
      'isActive': _isActive,
      'isHealthy': isHealthy,
      'lastUsedMinutesAgo': DateTime.now().difference(_lastUsedTime).inMinutes,
      'disposed': _disposed,
    };
  }
}
