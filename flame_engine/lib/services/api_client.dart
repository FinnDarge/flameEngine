import 'dart:convert';
import 'package:http/http.dart' as http;

const String kApiBase = 'https://tokenandboard.schokoladensouffle.eu/api';

// Pass via: --dart-define=API_TOKEN=<your_token>
// Falls back to the development token when not provided.
const String kApiKey = String.fromEnvironment(
  'API_TOKEN',
  defaultValue: 'leuheidaeJoo1aNgeethei0sho0iek8i',
);

/// Exception thrown when an API call returns a non-success HTTP status.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Low-level HTTP client for the TokenAndBoard API.
///
/// All write/admin operations require the `x-api-key` header.
/// Player-scoped operations (sessions) require the `x-user-key` header.
class ApiClient {
  final String baseUrl;
  final String apiKey;

  /// Visible for testing – can be replaced with a [http.MockClient].
  http.Client httpClient;

  ApiClient({
    this.baseUrl = kApiBase,
    this.apiKey = kApiKey,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  // ── Header builders ─────────────────────────────────────────────────────────

  Map<String, String> _adminHeaders() => {
    'x-api-key': apiKey,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Map<String, String> _readHeaders() => {'Accept': 'application/json'};

  Map<String, String> _userHeaders(String userKey) => {
    'x-user-key': userKey,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── HTTP helpers ─────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  /// Decode a JSON list response body.
  List<Map<String, dynamic>> _decodeList(http.Response resp) {
    _assertSuccess(resp);
    final data = json.decode(resp.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  /// Decode a single JSON object response body.
  Map<String, dynamic> _decodeObject(http.Response resp) {
    _assertSuccess(resp);
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  void _assertSuccess(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String message = resp.body;
      try {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        message = body['message'] as String? ?? message;
      } catch (_) {}
      throw ApiException(resp.statusCode, message);
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// GET a list resource (no auth required).
  Future<List<Map<String, dynamic>>> getList(
    String path, [
    Map<String, String>? queryParams,
  ]) async {
    final resp = await httpClient.get(
      _uri(path, queryParams),
      headers: _readHeaders(),
    );
    return _decodeList(resp);
  }

  /// GET a single resource by UUID (no auth required).
  Future<Map<String, dynamic>> getOne(String path) async {
    final resp = await httpClient.get(_uri(path), headers: _readHeaders());
    return _decodeObject(resp);
  }

  /// POST with admin key (returns response body or null for 204).
  Future<Map<String, dynamic>?> adminPost(
    String path,
    Map<String, dynamic> body,
  ) async {
    final resp = await httpClient.post(
      _uri(path),
      headers: _adminHeaders(),
      body: json.encode(body),
    );
    _assertSuccess(resp);
    if (resp.statusCode == 204 || resp.body.isEmpty) return null;
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  /// PUT with admin key.
  Future<void> adminPut(String path, Map<String, dynamic> body) async {
    final resp = await httpClient.put(
      _uri(path),
      headers: _adminHeaders(),
      body: json.encode(body),
    );
    _assertSuccess(resp);
  }

  /// DELETE with admin key.
  Future<void> adminDelete(String path) async {
    final resp = await httpClient.delete(_uri(path), headers: _adminHeaders());
    _assertSuccess(resp);
  }

  /// POST with user key (player-scoped, returns response body or null for 204).
  Future<Map<String, dynamic>?> userPost(
    String path,
    Map<String, dynamic> body,
    String userKey,
  ) async {
    final resp = await httpClient.post(
      _uri(path),
      headers: _userHeaders(userKey),
      body: json.encode(body),
    );
    _assertSuccess(resp);
    if (resp.statusCode == 204 || resp.body.isEmpty) return null;
    return json.decode(resp.body) as Map<String, dynamic>;
  }

  /// GET with redirect-following – used for joinCode lookup (302 → 200).
  /// Returns the resolved path segment after the last '/'.
  Future<Map<String, dynamic>> getFollowingRedirect(String path) async {
    // The http package follows redirects automatically; the final response
    // body contains the session JSON.
    final resp = await httpClient.get(_uri(path), headers: _readHeaders());
    return _decodeObject(resp);
  }
}
