import '../models/game_state.dart';
import '../services/management_api_service.dart' show ApiGame, ApiPlayer;
import '../services/session_api_service.dart'
    show
        ApiRole,
        CreatedSession,
        SessionApiService,
        SessionDetail,
        SessionPlayer;

/// Coordinates create/join/start session flows and writes authoritative values
/// back into [GameState].
class SessionFlowController {
  final SessionApiService _sessionApi;
  final Set<String> _roleJoinAttempts = <String>{};

  SessionFlowController({required SessionApiService sessionApi})
    : _sessionApi = sessionApi;

  Future<CreatedSession> createSession({
    required GameState gameState,
    required ApiPlayer player,
    required ApiGame game,
  }) async {
    final created = await _sessionApi.createSession(
      gameUuid: game.uuid,
      userKey: player.accessToken,
    );

    gameState
      ..sessionUuid = created.uuid
      ..sessionId = created.joinCode
      ..localApiPlayer = player
      ..selectedApiGame = game
      ..sessionCreatorUuid = player.uuid;

    return created;
  }

  Future<SessionJoinResult> joinSessionByCode({
    required GameState gameState,
    required ApiPlayer player,
    required String joinCode,
  }) async {
    final detail = await _sessionApi.getSessionByJoinCode(joinCode);
    final players = await _sessionApi.getSessionPlayers(detail.uuid);

    ApiGame? selectedGame;
    try {
      selectedGame = gameState.apiGames.firstWhere((g) => g.uuid == detail.game);
    } catch (_) {
      selectedGame = null;
    }

    gameState
      ..sessionUuid = detail.uuid
      ..sessionId = detail.joinCode
      ..localApiPlayer = player
      ..selectedApiGame = selectedGame
      ..sessionCreatorUuid = detail.creator
      ..sessionPlayers = players;

    return SessionJoinResult(detail: detail, players: players);
  }

  Future<List<ApiRole>> getRolesForGame(String gameUuid) {
    return _sessionApi.getRolesForGame(gameUuid);
  }

  Future<List<SessionPlayer>> getSessionPlayers(String sessionUuid) {
    return _sessionApi.getSessionPlayers(sessionUuid);
  }

  Future<void> ensureLobbyReady(GameState gameState) async {
    final sessionUuid = _requireSessionUuid(gameState);
    final detail = await _sessionApi.getSession(sessionUuid);
    gameState
      ..sessionUuid = detail.uuid
      ..sessionId = detail.joinCode
      ..sessionCreatorUuid = detail.creator;
  }

  Future<void> claimRoleForLocalPlayer({
    required GameState gameState,
    required String roleUuid,
  }) async {
    final sessionUuid = _requireSessionUuid(gameState);
    final userKey = _requireLocalAccessToken(gameState);
    final dedupeKey = '$sessionUuid::$userKey::$roleUuid';

    if (_roleJoinAttempts.contains(dedupeKey)) {
      throw StateError('Duplicate join attempt blocked for this role.');
    }

    _roleJoinAttempts.add(dedupeKey);
    try {
      await _sessionApi.joinSession(
        sessionUuid: sessionUuid,
        roleUuid: roleUuid,
        userKey: userKey,
      );
    } catch (_) {
      _roleJoinAttempts.remove(dedupeKey);
      rethrow;
    }
  }

  Future<void> startSession(GameState gameState) async {
    final sessionUuid = _requireSessionUuid(gameState);
    final userKey = _requireLocalAccessToken(gameState);
    await _sessionApi.startSession(sessionUuid: sessionUuid, userKey: userKey);
  }

  String _requireSessionUuid(GameState gameState) {
    final sessionUuid = gameState.sessionUuid;
    if (sessionUuid == null || sessionUuid.isEmpty) {
      throw StateError('Missing sessionUuid. Create or join a session first.');
    }
    return sessionUuid;
  }

  String _requireLocalAccessToken(GameState gameState) {
    final token = gameState.localApiPlayer?.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Missing localApiPlayer.accessToken for session action.');
    }
    return token;
  }
}

class SessionJoinResult {
  final SessionDetail detail;
  final List<SessionPlayer> players;

  const SessionJoinResult({required this.detail, required this.players});
}
