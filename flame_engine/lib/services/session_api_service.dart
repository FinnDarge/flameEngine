import 'api_client.dart';

/// A 2D position as returned by the database.
class PointObject {
  final num x;
  final num y;

  const PointObject({required this.x, required this.y});

  factory PointObject.fromJson(Map<String, dynamic> json) => PointObject(
        x: json['x'] as num,
        y: json['y'] as num,
      );

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

/// A board field annotated with the pieces currently on it.
class SessionBoardField {
  final String uuid;
  final PointObject position;
  final String? nfcId;
  final List<String> pieces; // UUIDs of pieces currently on this field

  const SessionBoardField({
    required this.uuid,
    required this.position,
    this.nfcId,
    required this.pieces,
  });

  factory SessionBoardField.fromJson(Map<String, dynamic> json) =>
      SessionBoardField(
        uuid: json['uuid'] as String,
        position:
            PointObject.fromJson(json['position'] as Map<String, dynamic>),
        nfcId: json['nfcId'] as String?,
        pieces: (json['pieces'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  @override
  String toString() =>
      'SessionBoardField(pos: (${position.x}, ${position.y}), pieces: ${pieces.length})';
}

/// An available move for the current player.
class Move {
  final String field;
  final String? label; // "Move" if empty, "Join" if occupied

  const Move({required this.field, this.label});

  factory Move.fromJson(Map<String, dynamic> json) => Move(
        field: json['field'] as String,
        label: json['label'] as String?,
      );

  @override
  String toString() => 'Move(field: $field, label: $label)';
}

/// Result from a successful walk movement.
class WalkResult {
  final String message;

  const WalkResult({required this.message});

  factory WalkResult.fromJson(Map<String, dynamic> json) => WalkResult(
        message: json['message'] as String,
      );

  @override
  String toString() => 'WalkResult($message)';
}

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
    final body = await _client.userPost(
        '/sessions',
        {
          'game': gameUuid,
        },
        userKey);
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
    await _client.userPost(
        '/sessions/$sessionUuid/join',
        {
          'role': roleUuid,
        },
        userKey);
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

  /// Start a session (transition to ready-to-play state).
  ///
  /// All roles must be filled with players, and all pieces must be initialized
  /// on their starting fields. The backend returns 204 on success.
  Future<void> startSession({
    required String sessionUuid,
    required String userKey,
  }) async {
    await _client.userPost('/sessions/$sessionUuid/start', {}, userKey);
  }

  /// Get the current board state for a session.
  ///
  /// Returns an array of [SessionBoardField] objects, each with position,
  /// NFC ID, and the UUIDs of pieces currently on that field.
  Future<List<SessionBoardField>> getSessionBoard({
    required String sessionUuid,
    required String userKey,
  }) async {
    final list = await _client.userGetList(
        '/sessionBoard', {'session': sessionUuid}, userKey);
    return list.map(SessionBoardField.fromJson).toList();
  }

  /// Get available moves for the current player's piece in a session.
  ///
  /// Returns an array of [Move] objects, each with field UUID and label
  /// ("Move" for empty, "Join" for occupied).
  Future<List<Move>> getSessionMoves({
    required String sessionUuid,
    required String userKey,
  }) async {
    final list = await _client.userGetList(
        '/sessionMoves', {'session': sessionUuid}, userKey);
    return list.map(Move.fromJson).toList();
  }

  /// Move the current player's piece to a target field.
  ///
  /// The target field should be one of the fields returned by [getSessionMoves].
  /// Returns a [WalkResult] with a confirmation message.
  Future<WalkResult> walkToField({
    required String sessionUuid,
    required String targetFieldUuid,
    required String userKey,
  }) async {
    final body = await _client.userPost(
      '/sessionMoves/walk',
      {'target': targetFieldUuid},
      userKey,
      queryParams: {'session': sessionUuid},
    );
    return WalkResult.fromJson(body!);
  }
}
