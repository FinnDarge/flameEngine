import 'api_client.dart';

/// A role available for a game (used when joining a session).
class ApiRole {
  final String uuid;
  final String name;

  const ApiRole({required this.uuid, required this.name});

  factory ApiRole.fromJson(Map<String, dynamic> json) =>
      ApiRole(uuid: json['uuid'] as String, name: json['name'] as String);

  @override
  String toString() => 'ApiRole($name)';
}

/// A player's assignment to a role in a session.
class SessionPlayer {
  final String uuid;
  final String session;
  final String player;
  final String role;

  const SessionPlayer({
    required this.uuid,
    required this.session,
    required this.player,
    required this.role,
  });

  factory SessionPlayer.fromJson(Map<String, dynamic> json) => SessionPlayer(
    uuid: json['uuid'] as String,
    session: json['session'] as String,
    player: json['player'] as String,
    role: json['role'] as String,
  );

  @override
  String toString() => 'SessionPlayer(player: $player, role: $role)';
}

/// Typed result from creating a session.
class CreatedSession {
  final String uuid;
  final String joinCode;

  const CreatedSession({required this.uuid, required this.joinCode});

  factory CreatedSession.fromJson(Map<String, dynamic> json) => CreatedSession(
    uuid: json['uuid'] as String,
    joinCode: json['joinCode'] as String,
  );
}

/// Typed result from looking up a session (by UUID or join code).
class SessionDetail {
  final String uuid;
  final String creator;
  final String game;
  final String joinCode;

  const SessionDetail({
    required this.uuid,
    required this.creator,
    required this.game,
    required this.joinCode,
  });

  factory SessionDetail.fromJson(Map<String, dynamic> json) => SessionDetail(
    uuid: json['uuid'] as String,
    creator: json['creator'] as String,
    game: json['game'] as String,
    joinCode: json['joinCode'] as String,
  );
}

/// Service for session lifecycle API calls.
///
/// All mutating calls require the player's `x-user-key` (access token).
class SessionApiService {
  final ApiClient _client;

  SessionApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Create a new session for [gameUuid] as the player identified by
  /// [userKey]. Returns the new session UUID and 8-character join code.
  Future<CreatedSession> createSession({
    required String gameUuid,
    required String userKey,
  }) async {
    final body = await _client.userPost('/sessions', {
      'game': gameUuid,
    }, userKey);
    return CreatedSession.fromJson(body!);
  }

  /// Fetch all roles available for [gameUuid].
  Future<List<ApiRole>> getRolesForGame(String gameUuid) async {
    final list = await _client.getList('/roles', {'game': gameUuid});
    return list.map(ApiRole.fromJson).toList();
  }

  /// Join an existing [sessionUuid] with the specified [roleUuid].
  ///
  /// The backend returns 204 on success.
  Future<void> joinSession({
    required String sessionUuid,
    required String roleUuid,
    required String userKey,
  }) async {
    await _client.userPost('/sessions/$sessionUuid/join', {
      'role': roleUuid,
    }, userKey);
  }

  /// Look up a session by its 8-character [joinCode].
  ///
  /// The backend responds with a 302 redirect to `/sessions/{uuid}`; the
  /// [ApiClient.getFollowingRedirect] call follows it and returns the full
  /// [SessionDetail].
  Future<SessionDetail> getSessionByJoinCode(String joinCode) async {
    final body = await _client.getFollowingRedirect(
      '/sessions/joinCode/$joinCode',
    );
    return SessionDetail.fromJson(body);
  }

  /// Get session details by UUID.
  Future<SessionDetail> getSession(String sessionUuid) async {
    final body = await _client.getOne('/sessions/$sessionUuid');
    return SessionDetail.fromJson(body);
  }

  /// Get all players currently in a session with their assigned roles.
  Future<List<SessionPlayer>> getSessionPlayers(String sessionUuid) async {
    final list = await _client.getList('/sessions/$sessionUuid/join', {});
    return list.map(SessionPlayer.fromJson).toList();
  }
}
